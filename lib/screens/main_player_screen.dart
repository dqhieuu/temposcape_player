import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:temposcape_player/screens/song_queue_screen.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import '../utils/utils.dart';

class MainPlayerScreen extends StatefulWidget {
  @override
  _MainPlayerScreenState createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> {
  final audioQuery = FlutterAudioQuery();

  Future<void> _downloadMusicToPhone(
      BuildContext context, String url, String title,
      {String checkSum}) async {
    if (url == null || !url.startsWith('http')) {
      showSnackBar(context, text: 'Cannot download this song.');
      return;
    }

    // Example: [Temposcape] Song name [123456789A].mp3
    final file = File(
        ('${await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_MUSIC)}'
            '/[${Constants.appName}] '
            '${title?.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '-') ?? ''}'
            ' ${checkSum != null ? '[$checkSum]' : ''}.mp3'));

    file.writeAsBytesSync((await http.get(url)).bodyBytes);
    await refreshMediaStore([file.path]);
    setState(() {});
    showSnackBar(
      context,
      text: 'Successfully downloaded ${truncateText(title, 20)}.mp3.',
    );
  }

  Future<bool> _fileAlreadyExists(String checkSum) async {
    final path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_MUSIC);
    Directory dir = Directory(path);
    return dir.listSync().any((file) => file.path.contains(checkSum));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent keyboard from resizing the widget
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 48,
            color: Theme.of(context).textTheme.bodyText1.color,
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<MediaItem>(
          stream: AudioService.currentMediaItemStream,
          builder: (context, snapshot) {
            final duration = snapshot.data?.duration ?? Duration.zero;
            final song = snapshot.data;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Flex(
                direction:
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? Axis.vertical
                        : Axis.horizontal,
                children: <Widget>[
                  // Displayed on top if orientation = vertical,
                  // on the left side if horizontal
                  buildLeftSideWidget(context, song),
                  const SizedBox(height: 30, width: 10),
                  // Displayed at the bottom if orientation = vertical,
                  // on the right side if horizontal
                  buildRightSideWidget(song, context, duration),
                ],
              ),
            );
          }),
    );
  }

  Widget buildRightSideWidget(
      MediaItem song, BuildContext context, Duration duration) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<MediaItem>(
                  stream: AudioService.currentMediaItemStream,
                  builder: (context, snapshot) {
                    return (snapshot.data?.extras ?? {})['isOnline'] ?? false
                        ? FutureBuilder<bool>(
                            future: _fileAlreadyExists(
                                (AudioService.currentMediaItem?.extras ??
                                    {})['checkSum']),
                            initialData: false,
                            builder: (_, snapshot) {
                              bool fileAlreadyDownloaded = snapshot.data;
                              return IconButton(
                                // downloadable if online
                                icon: Icon(Icons.download_rounded),
                                disabledColor: Colors.green.shade300,
                                onPressed: fileAlreadyDownloaded
                                    ? null
                                    : () async {
                                        final mediaItem =
                                            AudioService.currentMediaItem;
                                        await _downloadMusicToPhone(
                                            context,
                                            (mediaItem?.extras ?? {})['uri'],
                                            mediaItem?.title,
                                            checkSum: (mediaItem?.extras ??
                                                {})['checkSum']);
                                      },
                              );
                            })
                        : FutureBuilder<List<PlaylistInfo>>(
                            // add to playlist-able if offline
                            future: audioQuery.getPlaylists(),
                            builder: (context, snapshot) {
                              final favoritesPlaylist = snapshot.data
                                  ?.where((element) =>
                                      element.name ==
                                      Constants.favoritesPlaylistHiveBox)
                                  ?.first;
                              if (favoritesPlaylist == null) return Container();
                              return FutureBuilder<List<SongInfo>>(
                                  future: audioQuery.getSongsFromPlaylist(
                                      playlist: favoritesPlaylist),
                                  builder: (context, snapshot) {
                                    if (snapshot.data == null)
                                      return Container();
                                    final currentSongTypeCasted =
                                        AudioService.currentMediaItem != null
                                            ? mediaItemToSongInfo(
                                                AudioService.currentMediaItem)
                                            : null;
                                    bool hasCurrentSong = snapshot.data.any(
                                        (element) =>
                                            element.id ==
                                            currentSongTypeCasted?.id);
                                    if (hasCurrentSong) {
                                      return IconButton(
                                          icon: Icon(Icons.favorite_rounded),
                                          onPressed: () async {
                                            await favoritesPlaylist.removeSong(
                                                song: currentSongTypeCasted);
                                            setState(() {});
                                          });
                                    }
                                    return IconButton(
                                        icon:
                                            Icon(Icons.favorite_border_rounded),
                                        onPressed: () async {
                                          await favoritesPlaylist.addSong(
                                              song: currentSongTypeCasted);
                                          setState(() {});
                                        });
                                  });
                            });
                  }),
              Column(
                children: [
                  MyMarquee(
                    song?.title ?? 'No song played',
                    alignment: Alignment.center,
                    width: 250,
                    height: 35,
                    fontSize: 24,
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  MyMarquee(
                    song?.artist ?? 'Source not found',
                    alignment: Alignment.center,
                    width: 250,
                    height: 25,
                    fontSize: 16,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.caption.color,
                    ),
                  ),
                ],
              ),
              IconButton(
                  icon: Icon(Icons.queue_music),
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SongQueueScreen()));
                  })
            ],
          ),
          StreamBuilder<Duration>(
              stream: AudioService.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: PlayerSeekBar(
                    duration: duration,
                    position: position,
                    onChangeEnd: (value) {
                      AudioService.seekTo(value);
                    },
                  ),
                );
              }),
          PlayerControlBar(),
        ],
      ),
    );
  }

  Container buildLeftSideWidget(BuildContext context, MediaItem song) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).textTheme.bodyText1.color.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 12,
            offset: Offset(0, 0), // changes position of shadow
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundImage: (song?.artUri != null
            ? ((song?.extras ?? {})['isOnline'] ?? false
                ? CachedNetworkImageProvider(song.artUri)
                : Image.file(File(Uri.parse(song.artUri).path)).image)
            : AssetImage(Constants.defaultImagePath)),
        radius: 140,
      ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.center,
          width: 60,
          child: Text(
            getFormattedDuration(
              widget.position,
              timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData.fromPrimaryColors(
              primaryColor: Theme.of(context).accentColor,
              primaryColorDark: Theme.of(context).accentColor,
              primaryColorLight: Theme.of(context).accentColor,
              valueIndicatorTextStyle: TextStyle(),
            ).copyWith(
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                  disabledThumbRadius: 6,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 16,
                )),
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
        ),
        Container(
          alignment: Alignment.center,
          width: 60,
          child: Text(
            getFormattedDuration(
              widget.duration,
              timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
            ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: Icon(shuffleMode == AudioServiceShuffleMode.all
                      ? CupertinoIcons.shuffle
                      : CupertinoIcons.shuffle),
                  onPressed: () {
                    switch (shuffleMode) {
                      case AudioServiceShuffleMode.all:
                        AudioService.setShuffleMode(
                            AudioServiceShuffleMode.none);
                        showSnackBar(context, text: 'Shuffle OFF');
                        break;
                      case AudioServiceShuffleMode.none:
                        AudioService.setShuffleMode(
                            AudioServiceShuffleMode.all);
                        showSnackBar(context, text: 'Shuffle ON');
                        break;
                      default:
                        break;
                    }
                  },
                  color: shuffleMode == AudioServiceShuffleMode.none
                      ? Theme.of(context)
                          .textTheme
                          .bodyText1
                          .color
                          .withOpacity(0.2)
                      : null),
              SizedBox(
                width: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: AudioService.skipToPrevious,
                      icon: Icon(FontAwesomeIcons.backward),
                    ),
                    GestureDetector(
                      child: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 60,
                      ),
                      onTap: () {
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
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  switch (repeatMode) {
                    case AudioServiceRepeatMode.none:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.all);
                      showSnackBar(context, text: 'Loop the entire queue');
                      break;
                    case AudioServiceRepeatMode.all:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.one);
                      showSnackBar(context, text: 'Loop only this song');
                      break;
                    case AudioServiceRepeatMode.one:
                      AudioService.setRepeatMode(AudioServiceRepeatMode.none);
                      showSnackBar(context, text: 'Loop OFF');
                      break;
                    default:
                      break;
                  }
                },
                icon: Icon(
                  repeatMode == AudioServiceRepeatMode.none
                      ? CupertinoIcons.repeat
                      : repeatMode == AudioServiceRepeatMode.all
                          ? CupertinoIcons.repeat
                          : CupertinoIcons.repeat_1,
                  color: repeatMode == AudioServiceRepeatMode.none
                      ? Theme.of(context)
                          .textTheme
                          .bodyText1
                          .color
                          .withOpacity(0.2)
                      : null,
                ),
              ),
            ],
          );
        });
  }
}
