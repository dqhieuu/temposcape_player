import 'dart:core';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrobblenaut/scrobblenaut.dart' as scrobblenaut;
import 'package:temposcape_player/screens/home_screen.dart';

import 'constants/constants.dart' as Constants;
import 'screens/home_screen.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>(Constants.cachedArtists);
  await Hive.openBox<String>(Constants.cachedGenres);
  runApp(MyApp());
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
        home: AudioServiceWidget(child: HomeScreen()),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    final lastFmAuth =
        scrobblenaut.LastFM.noAuth(apiKey: Constants.lastFmApiKey);
    scrobblenaut.Scrobblenaut(lastFM: lastFmAuth);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
