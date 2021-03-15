import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import 'constants.dart' as Constants;
import 'utils.dart';

void main() {
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
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AudioServiceWidget(child: HomePage()),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// A home page where songs are displayed.
class HomePage extends StatelessWidget {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayer>(
      builder: (_, player, __) => DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home page'),
            bottom: TabBar(
              isScrollable: true,
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(text: 'Songs'),
                Tab(text: 'Albums'),
                Tab(text: 'Artists'),
                Tab(text: 'Playlists'),
                Tab(text: 'Favorites'),
                Tab(text: 'Genres'),
              ],
            ),
          ),
          drawer: Drawer(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Text('Drawer Header'),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
                ListTile(
                  title: Text('Item 1'),
                  onTap: () {
                    // Update the state of the app.
                    // ...
                  },
                ),
                ListTile(
                  title: Text('Item 2'),
                  onTap: () {
                    // Update the state of the app.
                    // ...
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(children: [
                  FutureBuilder<List<SongInfo>>(
                      future: audioQuery.getSongs(),
                      builder: (context, snapshot) {
                        final songs = snapshot.data;
                        return StreamBuilder<SequenceState>(
                            stream: player.sequenceStateStream,
                            builder: (context, snapshot) {
                              return ListView(
                                children: songs
                                        ?.where((song) => !song.filePath
                                            .contains(r'/Android/media/'))
                                        ?.map((SongInfo song) => SongListTile(
                                              song: song,
                                              onTap: () {
                                                player.setAudioSource(
                                                    ProgressiveAudioSource(
                                                        Uri.file(song.filePath),
                                                        tag: song));
                                                player.play();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          MainPlayerPage()),
                                                );
                                              },
                                              selected: (snapshot
                                                          .data
                                                          ?.currentSource
                                                          ?.tag as SongInfo)
                                                      ?.filePath ==
                                                  song.filePath,
                                            ))
                                        ?.toList() ??
                                    [],
                              );
                            });
                      }),
                  Icon(Icons.directions_transit),
                  Icon(Icons.directions_bike),
                  Icon(Icons.directions_transit),
                  Icon(Icons.directions_bike),
                  Icon(Icons.directions_transit),
                ]),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainPlayerPage()),
                  );
                },
                child: Container(
                  height: 70,
                  decoration:
                      BoxDecoration(color: Theme.of(context).bottomAppBarColor),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          return StreamBuilder<SequenceState>(
                              stream: player.sequenceStateStream,
                              builder: (context, snapshot) {
                                final SongInfo song =
                                    snapshot.data?.currentSource?.tag;
                                return Row(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: song?.albumArtwork != null
                                          ? Image.file(File(song.albumArtwork))
                                          : Image(
                                              image: AssetImage(
                                                  Constants.defaultImagePath)),
                                    ),
                                    VerticalDivider(
                                      thickness: 2,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            song?.title ?? 'Nyoron',
                                            style: TextStyle(
                                              fontSize: 20,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            song?.artist ??
                                                'Churuyaffffffffffffff',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    VerticalDivider(
                                      thickness: 2,
                                    ),
                                    StreamBuilder<PlayerState>(
                                        stream: player.playerStateStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.data?.playing ?? false) {
                                            return IconButton(
                                              onPressed: () {
                                                player.pause();
                                              },
                                              icon:
                                                  Icon(FontAwesomeIcons.pause),
                                            );
                                          }
                                          return IconButton(
                                            onPressed: () {
                                              player.play();
                                            },
                                            icon: Icon(FontAwesomeIcons.play),
                                          );
                                        }),
                                  ],
                                );
                              });
                        }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SongListTile extends StatelessWidget {
  final SongInfo song;
  final GestureTapCallback onTap;
  final bool selected;

  const SongListTile({
    Key key,
    this.song,
    this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        child: song.albumArtwork != null
            ? Image.file(File(song.albumArtwork))
            : Image(image: AssetImage(Constants.defaultImagePath)),
      ),
      onTap: onTap,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      trailing: Text(
        getFormattedDuration(
          Duration(milliseconds: int.parse(song.duration)),
          timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
        ),
      ),
    );
  }
}

class MainPlayerPage extends StatefulWidget {
  @override
  _MainPlayerPageState createState() => _MainPlayerPageState();
}

class _MainPlayerPageState extends State<MainPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayer>(
      builder: (_, player, __) => Scaffold(
        appBar: AppBar(
          title: Text('Main player'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                StreamBuilder<SequenceState>(
                    stream: player.sequenceStateStream,
                    builder: (context, snapshot) {
                      return PlayerSongInfo(
                          snapshot.data?.currentSource?.tag as SongInfo);
                    }),
                StreamBuilder<Duration>(
                    stream: player.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            return PlayerSeekBar(
                              duration: duration,
                              position: position,
                              onChangeEnd: (value) {
                                player.seek(value);
                              },
                            );
                          });
                    }),
                PlayerControlBar(player),
              ],
            )),
      ),
    );
  }
}

class PlayerSongInfo extends StatelessWidget {
  final SongInfo song;

  const PlayerSongInfo(
    this.song, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: song?.albumArtwork != null
              ? Image.file(File(song?.albumArtwork))
              : Image(image: AssetImage(Constants.defaultImagePath)),
          width: 300,
          height: 300,
        ),
        Text(
          song?.title ?? 'Nyoron',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          song?.artist ?? 'Churuya',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.caption.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class PlayerSeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;
  const PlayerSeekBar(
      {Key key,
      @required this.duration,
      @required this.position,
      this.onChanged,
      this.onChangeEnd})
      : super(key: key);

  @override
  _PlayerSeekBarState createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  double _dragValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          getFormattedDuration(
            widget.position,
            timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
          ),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: _dragValue ??
                min(widget.position.inMilliseconds.toDouble(),
                    widget.duration.inMilliseconds.toDouble()),
            onChanged: (double value) {
              setState(() {
                _dragValue = value;
              });
            },
            onChangeEnd: (double value) {
              _dragValue = null;
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd(Duration(milliseconds: value.round()));
              }
            },
          ),
        ),
        Text(
          getFormattedDuration(
            widget.duration,
            timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
          ),
        ),
      ],
    );
  }
}

class PlayerControlBar extends StatelessWidget {
  final AudioPlayer player;

  const PlayerControlBar(this.player);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StreamBuilder<bool>(
            stream: player.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final shuffleModeEnabled = snapshot.data ?? false;
              return IconButton(
                icon: Icon(shuffleModeEnabled
                    ? MdiIcons.shuffle
                    : MdiIcons.shuffleDisabled),
                onPressed: () {
                  player.setShuffleModeEnabled(!shuffleModeEnabled);
                },
              );
            }),
        Icon(FontAwesomeIcons.backward),
        StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              if (snapshot.data?.playing ?? false) {
                return IconButton(
                  onPressed: () {
                    player.pause();
                  },
                  icon: Icon(FontAwesomeIcons.pause),
                );
              }
              return IconButton(
                onPressed: () {
                  player.play();
                },
                icon: Icon(FontAwesomeIcons.play),
              );
            }),
        Icon(FontAwesomeIcons.forward),
        StreamBuilder<LoopMode>(
            stream: player.loopModeStream,
            builder: (context, snapshot) {
              if (snapshot.data == LoopMode.off) {
                return IconButton(
                  onPressed: () {
                    player.setLoopMode(LoopMode.all);
                  },
                  icon: Icon(
                    MdiIcons.repeatOff,
                  ),
                );
              } else if (snapshot.data == LoopMode.one) {
                return IconButton(
                  onPressed: () {
                    player.setLoopMode(LoopMode.off);
                  },
                  icon: Icon(Icons.repeat_one),
                );
              }
              return IconButton(
                onPressed: () {
                  player.setLoopMode(LoopMode.one);
                },
                icon: const Icon(Icons.repeat),
              );
            }),
      ],
    );
  }
}
