import 'dart:core';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrobblenaut/scrobblenaut.dart';
import 'package:temposcape_player/models/artist_cache.dart';
import 'package:temposcape_player/screens/home_screen.dart';

import 'constants/constants.dart' as Constants;
import 'screens/home_screen.dart';

void main() async {
  // Init LastFM library
  Scrobblenaut(lastFM: LastFM.noAuth(apiKey: Constants.lastFmApiKey));
  // Init Hive database
  await Hive.initFlutter();
  Hive.registerAdapter(ArtistCacheAdapter());
  await Hive.openBox<ArtistCache>(ArtistCache.hiveBox);
  Hive.openBox<String>(Constants.cachedGenres);
  // Run main app
  runApp(MyApp());
}

void _audioPlayerTaskEntryPoint() =>
    AudioServiceBackground.run(() => AudioPlayerTask());

/// This class creates a just_audio audio player instance wrapped in
/// a background task
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
          // AppLocalizations.delegate,
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

    SongSortType.DEFAULT;
    SongSortType.CURRENT_IDs_ORDER;
    SongSortType.ALPHABETIC_ALBUM;
    SongSortType.ALPHABETIC_ARTIST;
    SongSortType.ALPHABETIC_COMPOSER;
    SongSortType.DISPLAY_NAME;
    SongSortType.GREATER_DURATION;
    SongSortType.SMALLER_DURATION;
    SongSortType.GREATER_TRACK_NUMBER;
    SongSortType.SMALLER_TRACK_NUMBER;
    SongSortType.RECENT_YEAR;
    SongSortType.OLDEST_YEAR;

    AlbumSortType.DEFAULT;
    AlbumSortType.CURRENT_IDs_ORDER;
    AlbumSortType.ALPHABETIC_ARTIST_NAME;
    AlbumSortType.MORE_SONGS_NUMBER_FIRST;
    AlbumSortType.LESS_SONGS_NUMBER_FIRST;
    AlbumSortType.MOST_RECENT_YEAR;
    AlbumSortType.OLDEST_YEAR;

    ArtistSortType.DEFAULT;
    ArtistSortType.CURRENT_IDs_ORDER;
    ArtistSortType.MORE_ALBUMS_NUMBER_FIRST;
    ArtistSortType.LESS_ALBUMS_NUMBER_FIRST;
    ArtistSortType.MORE_TRACKS_NUMBER_FIRST;
    ArtistSortType.LESS_TRACKS_NUMBER_FIRST;
  }

  @override
  void dispose() {
    _player.dispose();
    Hive.close();
    super.dispose();
  }
}
