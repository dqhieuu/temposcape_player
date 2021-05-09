import 'dart:core';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:scrobblenaut/scrobblenaut.dart';
import 'package:temposcape_player/models/artist_cache.dart';
import 'package:temposcape_player/models/settings_model.dart';
import 'package:temposcape_player/plugins/plugins.dart';
import 'package:temposcape_player/screens/home_screen.dart';
import 'package:temposcape_player/services/audio_player_task.dart';

import 'constants/constants.dart' as Constants;
import 'screens/home_screen.dart';

void main() async {
  // Init LastFM library
  Scrobblenaut(lastFM: LastFM.noAuth(apiKey: Constants.lastFmApiKey));
  // Init Hive database
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(SettingsModel.hiveBox);

  Hive.registerAdapter(ArtistCacheAdapter());
  await Hive.openBox<ArtistCache>(ArtistCache.hiveBox);

  await Hive.openBox<String>(Constants.playlistNamesHiveBox);

  final pluginStorage = <BasePlayerPlugin>[
    ChiaSeNhacPlugin(),
    ZingMp3Plugin(),
    NhacCuaTuiPlugin(),
    SoundCloudPlugin(),
    OnlineRadiosPlugin(),
  ];

  // Run main app
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsModel()),
      Provider.value(value: pluginStorage),
    ],
    child: MyApp(),
  ));
}

void _audioPlayerTaskEntryPoint() =>
    AudioServiceBackground.run(() => AudioPlayerTask());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(primarySwatch: Colors.deepPurple);
    final darkTheme = ThemeData.dark();

    return Consumer<SettingsModel>(
      builder: (_, settings, __) {
        final currentTheme = settings.darkMode ? darkTheme : lightTheme;
        return MaterialApp(
          title: Constants.appName,
          theme: currentTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(currentTheme.textTheme),
            primaryTextTheme:
                GoogleFonts.montserratTextTheme(currentTheme.textTheme)
                    .apply(bodyColor: Colors.white),
          ),
          // localizationsDelegates: [
          //   S.delegate,
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          // supportedLocales: S.delegate.supportedLocales,
          home: AudioServiceWidget(child: HomeScreen()),
        );
      },
    );
  }

  @override
  void initState() {
    AudioService.connect();
    AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
        androidNotificationIcon: 'drawable/ic_stat_app');
    super.initState();

    // SongSortType.DEFAULT;
    // SongSortType.CURRENT_IDs_ORDER;
    // SongSortType.ALPHABETIC_ALBUM;
    // SongSortType.ALPHABETIC_ARTIST;
    // SongSortType.ALPHABETIC_COMPOSER;
    // SongSortType.DISPLAY_NAME;
    // SongSortType.GREATER_DURATION;
    // SongSortType.SMALLER_DURATION;
    // SongSortType.GREATER_TRACK_NUMBER;
    // SongSortType.SMALLER_TRACK_NUMBER;
    // SongSortType.RECENT_YEAR;
    // SongSortType.OLDEST_YEAR;
    //
    // AlbumSortType.DEFAULT;
    // AlbumSortType.CURRENT_IDs_ORDER;
    // AlbumSortType.ALPHABETIC_ARTIST_NAME;
    // AlbumSortType.MORE_SONGS_NUMBER_FIRST;
    // AlbumSortType.LESS_SONGS_NUMBER_FIRST;
    // AlbumSortType.MOST_RECENT_YEAR;
    // AlbumSortType.OLDEST_YEAR;
    //
    // ArtistSortType.DEFAULT;
    // ArtistSortType.CURRENT_IDs_ORDER;
    // ArtistSortType.MORE_ALBUMS_NUMBER_FIRST;
    // ArtistSortType.LESS_ALBUMS_NUMBER_FIRST;
    // ArtistSortType.MORE_TRACKS_NUMBER_FIRST;
    // ArtistSortType.LESS_TRACKS_NUMBER_FIRST;
    //
    // SongSortType.DEFAULT;
    // SongSortType.ALPHABETIC_ALBUM;
    // SongSortType.ALPHABETIC_ARTIST;
    // SongSortType.DISPLAY_NAME;
    // SongSortType.SMALLER_DURATION;
    // SongSortType.OLDEST_YEAR;
    //
    // AlbumSortType.DEFAULT;
    // AlbumSortType.ALPHABETIC_ARTIST_NAME;
    // AlbumSortType.LESS_SONGS_NUMBER_FIRST;
    // AlbumSortType.OLDEST_YEAR;
    //
    // ArtistSortType.DEFAULT;
    // ArtistSortType.LESS_ALBUMS_NUMBER_FIRST;
    // ArtistSortType.LESS_TRACKS_NUMBER_FIRST;
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
}
