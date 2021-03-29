import 'dart:core';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrobblenaut/scrobblenaut.dart';
import 'package:temposcape_player/screens/home_screen.dart';

import 'constants/constants.dart' as Constants;
import 'screens/home_screen.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(Constants.cachedArtists);
  await Hive.openBox<String>(Constants.cachedGenres);
  runApp(MyApp());
}

void _audioPlayerTaskEntryPoint() =>
    AudioServiceBackground.run(() => AudioPlayerTask());

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
    await AudioServiceBackground.setQueue(queue);
    _queue = queue;
    _audioSource = ConcatenatingAudioSource(
      children: AudioServiceBackground.queue
          .map((e) => AudioSource.uri(
                Uri.parse(e.extras['filePath'] ?? e.extras['uri']),
                tag: e,
              ))
          .toList(),
    );
    await _player.setAudioSource(_audioSource);
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
      AudioServiceBackground.setState(
        position: position,
        shuffleMode: _shuffleMode,
        repeatMode: _repeatMode,
      );
    });
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AudioPlayer _player;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _player),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          brightness: Brightness.dark,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', 'US'),
          const Locale('vi', 'VN'),
        ],
        home: AudioServiceWidget(child: HomeScreen()),
      ),
    );
  }

  @override
  void initState() {
    AudioService.connect();
    AudioService.start(backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint);

    super.initState();
    // _player = AudioPlayer();
    // _player.playerStateStream.listen((event) async {
    //   if (event.processingState == ProcessingState.completed) {
    //     _player.pause();
    //     await _player.seek(Duration.zero);
    //   }
    // });
    Scrobblenaut(lastFM: LastFM.noAuth(apiKey: Constants.lastFmApiKey));
  }

  @override
  void dispose() {
    _player.dispose();
    Hive.close();
    super.dispose();
  }
}
