import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:temposcape_player/screens/song_queue_screen.dart';

import '../constants/constants.dart' as Constants;
import '../utils/utils.dart';

class MainPlayerScreen extends StatefulWidget {
  @override
  _MainPlayerScreenState createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> {
  static const platform = const MethodChannel('temposcape.flutter/refresh');

  final audioQuery = FlutterAudioQuery();

  Future<void> _refreshMediaStore(String path) async {
    try {
      final String result =
          await platform.invokeMethod('refreshMediaStore', {'path': path});
      print(result);
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> _downloadMusicToPhone(
      BuildContext context, String url, String title) async {
    if (url == null || !url.startsWith('http')) {
      final snackBar = SnackBar(content: Text('Cannot download this song.'));

      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    // Example: [Temposcape] Song name_1612315612.mp3
    final file = File(
        ('${await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_MUSIC)}'
            '/[${Constants.appName}] '
            '${title?.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '-') ?? ''}'
            '_${DateTime.now().millisecondsSinceEpoch}.mp3'));

    file.writeAsBytesSync((await http.get(url)).bodyBytes);
    await _refreshMediaStore(file.path);

    final snackBar = SnackBar(
        content: Text(
            'Successfully downloaded ${title.length <= 20 ? title : title + '...'}.mp3.'));

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main player'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              StreamBuilder<MediaItem>(
                  stream: AudioService.currentMediaItemStream,
                  builder: (context, snapshot) {
                    return PlayerSongInfo(snapshot.data);
                  }),
              StreamBuilder<MediaItem>(
                  stream: AudioService.currentMediaItemStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data?.duration ?? Duration.zero;
                    return StreamBuilder<Duration>(
                        stream: AudioService.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return PlayerSeekBar(
                            duration: duration,
                            position: position,
                            onChangeEnd: (value) {
                              AudioService.seekTo(value);
                            },
                          );
                        });
                  }),
              PlayerControlBar(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StreamBuilder<MediaItem>(
                      stream: AudioService.currentMediaItemStream,
                      builder: (context, snapshot) {
                        return (snapshot.data?.extras ?? {})['isOnline'] ??
                                false
                            ? IconButton(
                                icon: Icon(Icons.download_rounded),
                                onPressed: () async {
                                  final mediaItem =
                                      AudioService.currentMediaItem;
                                  await _downloadMusicToPhone(
                                      context,
                                      (mediaItem?.extras ?? {})['uri'],
                                      mediaItem?.title);
                                })
                            : IconButton(
                                icon: Icon(Icons.favorite),
                                onPressed: () async {
                                  final favoritesPlaylist =
                                      (await audioQuery.getPlaylists())
                                          ?.where((element) =>
                                              element.name ==
                                              Constants.favoritesPlaylist)
                                          ?.first;
                                  if (favoritesPlaylist == null ||
                                      snapshot.data == null) return;
                                  final currentSongTypeCasted =
                                      mediaItemToSongInfo(snapshot.data);
                                  bool hasCurrentSong =
                                      (await audioQuery.getSongsFromPlaylist(
                                              playlist: favoritesPlaylist))
                                          .any((element) =>
                                              element.id ==
                                              currentSongTypeCasted.id);
                                  if (hasCurrentSong) {
                                    print('hasCurrentSong');
                                    favoritesPlaylist.removeSong(
                                        song: currentSongTypeCasted);
                                  } else {
                                    favoritesPlaylist.addSong(
                                        song: currentSongTypeCasted);
                                    print('nothascurrentsong');
                                  }
                                });
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
  final MediaItem song;

  const PlayerSongInfo(
    this.song, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: (song?.artUri != null
              ? ((song?.extras ?? {})['isOnline'] ?? false
                  ? CachedNetworkImageProvider(song.artUri)
                  : Image.file(File(Uri.parse(song.artUri).path)).image)
              : AssetImage(Constants.defaultImagePath)),
          radius: 120,
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
        stream: AudioService.playbackStateStream,
        builder: (context, snapshot) {
          final shuffleMode =
              snapshot.data?.shuffleMode ?? AudioServiceShuffleMode.none;
          final repeatMode =
              snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
          final isPlaying = snapshot.data?.playing ?? false;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //   StreamBuilder<bool>(
              //       stream: player.shuffleModeEnabledStream,
              //       builder: (context, snapshot) {
              //         final shuffleModeEnabled = snapshot.data ?? false;
              //         return IconButton(
              //           icon: Icon(shuffleModeEnabled
              //               ? MdiIcons.shuffle
              //               : MdiIcons.shuffleDisabled),
              //           onPressed: () {
              //             player.setShuffleModeEnabled(!shuffleModeEnabled);
              //           },
              //         );
              //       }),
              //   IconButton(
              //     onPressed: () {
              //       player.seekToPrevious();
              //     },
              //     icon: Icon(FontAwesomeIcons.backward),
              //   ),
              //   StreamBuilder<PlayerState>(
              //       stream: player.playerStateStream,
              //       builder: (context, snapshot) {
              //         if (snapshot.data?.playing ?? false) {
              //           return IconButton(
              //             onPressed: () {
              //               player.pause();
              //             },
              //             icon: Icon(FontAwesomeIcons.pause),
              //           );
              //         }
              //         return IconButton(
              //           onPressed: () {
              //             player.play();
              //           },
              //           icon: Icon(FontAwesomeIcons.play),
              //         );
              //       }),
              //   IconButton(
              //     onPressed: () {
              //       player.seekToNext();
              //     },
              //     icon: Icon(FontAwesomeIcons.forward),
              //   ),
              //   StreamBuilder<LoopMode>(
              //       stream: player.loopModeStream,
              //       builder: (context, snapshot) {
              //         if (snapshot.data == LoopMode.off) {
              //           return IconButton(
              //             onPressed: () {
              //               player.setLoopMode(LoopMode.all);
              //             },
              //             icon: Icon(
              //               MdiIcons.repeatOff,
              //             ),
              //           );
              //         } else if (snapshot.data == LoopMode.one) {
              //           return IconButton(
              //             onPressed: () {
              //               player.setLoopMode(LoopMode.off);
              //             },
              //             icon: Icon(Icons.repeat_one),
              //           );
              //         }
              //         return IconButton(
              //           onPressed: () {
              //             player.setLoopMode(LoopMode.one);
              //           },
              //           icon: const Icon(Icons.repeat),
              //         );
              //       }),

              IconButton(
                icon: Icon(shuffleMode == AudioServiceShuffleMode.all
                    ? MdiIcons.shuffle
                    : MdiIcons.shuffleDisabled),
                onPressed: () {
                  switch (shuffleMode) {
                    case AudioServiceShuffleMode.all:
                      AudioService.setShuffleMode(AudioServiceShuffleMode.none);
                      break;
                    case AudioServiceShuffleMode.none:
                      AudioService.setShuffleMode(AudioServiceShuffleMode.all);
                      break;
                    default:
                      break;
                  }
                },
              ),
              IconButton(
                onPressed: AudioService.skipToPrevious,
                icon: Icon(FontAwesomeIcons.backward),
              ),
              IconButton(
                icon: Icon(
                    isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play),
                onPressed: () {
                  if (isPlaying) {
                    AudioService.pause();
                  } else {
                    AudioService.play();
                  }
                },
              ),
              IconButton(
                onPressed: AudioService.skipToNext,
                icon: Icon(FontAwesomeIcons.forward),
              ),
              IconButton(
                onPressed: () {
                  switch (repeatMode) {
                    case AudioServiceRepeatMode.none:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.all);
                      break;
                    case AudioServiceRepeatMode.all:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.one);
                      break;
                    case AudioServiceRepeatMode.one:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.none);
                      break;
                    default:
                      break;
                  }
                },
                icon: Icon(
                  repeatMode == AudioServiceRepeatMode.none
                      ? Icons.repeat
                      : repeatMode == AudioServiceRepeatMode.all
                          ? Icons.repeat
                          : Icons.repeat_one,
                  color: repeatMode == AudioServiceRepeatMode.none
                      ? Colors.red
                      : Colors.white,
                ),
              ),
            ],
          );
        });
  }
}
