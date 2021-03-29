// TODO: implement this
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:scrobblenaut/lastfm.dart' as lastfm;
import 'package:scrobblenaut/scrobblenaut.dart' as scrobblenaut;
import 'package:temposcape_player/utils/utils.dart';

import '../constants/constants.dart' as Constants;
import 'home_screen.dart';
import 'main_player_screen.dart';

class AlbumScreen extends StatefulWidget {
  final AlbumInfo albumInput;

  AlbumScreen({Key key, this.albumInput}) : super(key: key);

  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final audioQuery = FlutterAudioQuery();

  var songs = <SongInfo>[];

  @override
  Widget build(BuildContext context) {
    final albumArt = widget.albumInput.albumArt != null
        ? Image.file(File(widget.albumInput.albumArt)).image
        : AssetImage(Constants.defaultAlbumPath);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.albumInput.artist),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              child: Stack(
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withOpacity(0.5),
                          Colors.transparent, // <-- change this opacity
                          // Colors.transparent // <-- you might need this if you want full transparency at the edge
                        ],
                      ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height));
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image(
                      image: albumArt,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image(
                            image: albumArt,
                            fit: BoxFit.cover,
                            width: 160,
                            height: 160,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.albumInput.title,
                                maxLines: 2,
                              ),
                              Text(
                                widget.albumInput.artist,
                                maxLines: 1,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
                overflow: Overflow.visible,
              ),
            ),
            FutureBuilder<lastfm.Album>(
                future: scrobblenaut.Scrobblenaut.instance.album.getInfo(
                  artist: widget.albumInput.artist,
                  album: widget.albumInput.title,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final album = snapshot.data;
                    print(album.url);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Release date: ${album.url}'),
                          Text('Listener count: ${album.listeners}'),
                          Text('Play count: ${album.playCount}'),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Info'),
                  );
                }),
            FutureBuilder<List<SongInfo>>(
              future:
                  audioQuery.getSongsFromAlbum(albumId: widget.albumInput.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();
                final songs = snapshot.data.map(songInfoToMediaItem).toList();
                return Expanded(
                  child: ListView(
                      children: songs
                              ?.map((MediaItem song) => SongListTile(
                                    song: song,
                                    onTap: () async {
                                      await AudioService.updateQueue(
                                          songs.toList());
                                      await AudioService.skipToQueueItem(
                                          song.id);
                                      AudioService.play();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MainPlayerScreen()),
                                      );
                                    },
                                    // selected:
                                    //     (snapshot.data?.currentSource?.tag)
                                    //             ?.filePath ==
                                    //         song.filePath,
                                  ))
                              ?.toList() ??
                          []),
                );
              },
            ),
          ],
        ));
  }
}
