import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/screens/song_queue_screen.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import '../utils/utils.dart';

class MainPlayerScreen extends StatefulWidget {
  @override
  _MainPlayerScreenState createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> {
  static const platform = const MethodChannel('temposcape.flutter/refresh');

  Future<void> _refreshMediaStore(String path) async {
    try {
      final String result =
          await platform.invokeMethod('refreshMediaStore', {'path': path});
      print(result);
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  void _downloadMusicToPhone(String url, String title) async {
    if (url == null || !url.startsWith('http')) return;
    print(url);
    final file = File(
        '/storage/emulated/0/Music/downloaded_${title?.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '-') ?? ''}_${DateTime.now().millisecondsSinceEpoch}.mp3');
    file.writeAsBytesSync((await http.get(url)).bodyBytes);
    await _refreshMediaStore(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();
    return Scaffold(
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
                    return PlayerSongInfo(snapshot.data?.currentSource?.tag);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                      icon: Icon(Icons.download_rounded),
                      onPressed: () async {
                        final songInfo = (player
                            ?.sequenceState?.currentSource?.tag as SongInfo);
                        _downloadMusicToPhone(
                            songInfo?.filePath, songInfo?.title);
                      }),
                  IconButton(
                      icon: Icon(Icons.queue_music),
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SongQueueScreen()));
                      }),
                ],
              ),
            ],
          )),
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
        RoundedImage(
          image: song?.isPodcast ?? false
              ? (song?.albumArtwork != null
                  ? Image.network(song?.albumArtwork).image
                  : AssetImage(Constants.defaultImagePath))
              : (song?.albumArtwork != null
                  ? Image.file(File(song?.albumArtwork)).image
                  : AssetImage(Constants.defaultImagePath)),
          width: 250,
          height: 250,
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
        IconButton(
          onPressed: () {
            player.seekToPrevious();
          },
          icon: Icon(FontAwesomeIcons.backward),
        ),
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
        IconButton(
          onPressed: () {
            player.seekToNext();
          },
          icon: Icon(FontAwesomeIcons.forward),
        ),
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
