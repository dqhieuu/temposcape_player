import 'dart:core';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:temposcape_player/models/song_reorder.dart';

/// This class creates a just_audio audio player instance that is
/// completely isolated and interactable in background
class AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();

  var _shuffleMode = AudioServiceShuffleMode.none;
  var _repeatMode = AudioServiceRepeatMode.none;

  ConcatenatingAudioSource _audioSource;
  var _queue = <MediaItem>[];

  var _shuffledQueue = <MediaItem>[];

  List<MediaItem> get currentQueue =>
      _shuffleMode == AudioServiceShuffleMode.none ? _queue : _shuffledQueue;

  @override
  Future<void> onPlay() => _player.play();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration duration) => _player.seek(duration);

  @override
  Future<void> onSkipToQueueItem(String mediaId) {
    final newIndex =
        AudioServiceBackground.queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return null;
    return _player.seek(Duration.zero, index: newIndex);
  }

  @override
  Future<void> onSkipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> onSkipToNext() => _player.seekToNext();

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;

    AudioServiceBackground.setState(
      repeatMode: _repeatMode,
      shuffleMode: _shuffleMode,
    );

    final playerLoopMode = {
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.none: LoopMode.off
    }[repeatMode];

    await _player.setLoopMode(playerLoopMode);
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;

    await AudioServiceBackground.setState(
      repeatMode: _repeatMode,
      shuffleMode: _shuffleMode,
    );

    final playerShuffleMode = {
      AudioServiceShuffleMode.all: true,
      AudioServiceShuffleMode.none: false,
    }[shuffleMode];

    await _player.setShuffleModeEnabled(playerShuffleMode);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) async {
    _queue = queue;
    await AudioServiceBackground.setQueue(_queue);
    _audioSource = ConcatenatingAudioSource(
      children: _queue
          .map((e) => AudioSource.uri(
                Uri.parse(e.extras['filePath'] ?? e.extras['uri']),
                tag: e,
              ))
          .toList(),
    );
    await _player.setAudioSource(_audioSource);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    if (mediaItem == null) return;
    _audioSource.add(AudioSource.uri(
      Uri.parse(mediaItem.extras['filePath'] ?? mediaItem.extras['uri']),
      tag: mediaItem,
    ));
    _queue.add(mediaItem);
    AudioServiceBackground.setQueue(_queue);
  }

  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    if (mediaItem == null) return;
    _audioSource.removeAt(_audioSource.children.indexWhere((element) =>
        mediaItem.id == (element.sequence.first.tag as MediaItem).id));
    _queue.remove(mediaItem);
    AudioServiceBackground.setQueue(_queue);
  }

  Future<void> onMoveQueueItem(SongReorder order) async {
    if (order == null) return;
    final oldIndex = order.oldIndex;
    var newIndex = order.newIndex;
    if (oldIndex < newIndex) newIndex--;

    _audioSource.move(oldIndex, newIndex);

    final songMoved = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, songMoved);
    AudioServiceBackground.setQueue(_queue);
  }

  Future<void> onMakeShuffledOrderUnshuffledOrder() async {
    final newSongOrder = _player?.sequenceState?.effectiveSequence;
    if (newSongOrder == null) return;

    _audioSource = ConcatenatingAudioSource(children: newSongOrder);

    final currentItem = newSongOrder[_player.effectiveIndices
        .indexWhere((element) => _player.currentIndex == element)];
    final currentPosition = _player.position;

    await AudioService.setShuffleMode(AudioServiceShuffleMode.none);
    await AudioService.updateQueue(
        newSongOrder.map((e) => e.tag as MediaItem).toList());

    _player.seek(currentPosition, index: newSongOrder.indexOf(currentItem));
  }

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    switch (name) {
      case 'moveQueueItem':
        onMoveQueueItem(SongReorder.fromMap(arguments));
        break;
      case 'makeShuffledOrderUnshuffledOrder':
        onMakeShuffledOrderUnshuffledOrder();
        break;
    }
  }

  @override
  Future<void> onStop() async {
    await _player.dispose();
    await super.onStop();
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // Listen to state changes on the player...
    _player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: playerState.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
          ProcessingState.idle: AudioProcessingState.stopped,
        }[playerState.processingState],
        // Tell clients what buttons/controls should be enabled in the
        // current state.
        controls: [
          MediaControl.skipToPrevious,
          playerState.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        shuffleMode: _shuffleMode,
        repeatMode: _repeatMode,
      );
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || index < 0) return null;
      AudioServiceBackground.setMediaItem(_queue[index]);
    });

    _player.shuffleModeEnabledStream.listen((event) {});

    _player.loopModeStream.listen((event) {});

    // This sets the duration of the audio file to player's duration
    // if duration info is null.
    _player.durationStream.listen((duration) async {
      if (duration == null) return;
      MediaItem media = _player.sequenceState.currentSource.tag;
      final uri = media.extras['uri'];
      if (uri != null && media.duration == null) {
        final modifiedMedia = media.copyWith(duration: duration);
        await AudioServiceBackground.setQueue([modifiedMedia]);
        AudioServiceBackground.setMediaItem(modifiedMedia);
      }
    });

    _player.positionStream.listen((position) {
      // setState() resets shuffleMode and repeatMode if these
      // parameters are left null, that's why we need to keep their current state
      AudioServiceBackground.setState(
        position: position,
        shuffleMode: _shuffleMode,
        repeatMode: _repeatMode,
      );
    });
  }
}
