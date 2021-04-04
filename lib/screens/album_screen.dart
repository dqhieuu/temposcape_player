import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:scrobblenaut/lastfm.dart' as lastfm;
import 'package:scrobblenaut/scrobblenaut.dart' as scrobblenaut;
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

class AlbumScreen extends StatefulWidget {
  final AlbumInfo albumInput;

  const AlbumScreen({Key key, this.albumInput}) : super(key: key);

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
          title: Text(widget.albumInput.title),
        ),
        body: ListView(
          children: [
            ArtCoverHeader(
              height: 220,
              image: albumArt,
              content: Row(
                children: [
                  Image(
                    image: albumArt,
                    fit: BoxFit.cover,
                    width: 160,
                    height: 160,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.albumInput.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.albumInput.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
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
                          Text('Listener count: ${album.listeners}'),
                          Text('Play count: ${album.playCount}'),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No Info'),
                  );
                }),
            Text('Tracks'),
            FutureBuilder<List<SongInfo>>(
              future:
                  audioQuery.getSongsFromAlbum(albumId: widget.albumInput.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();
                final songs = snapshot.data.map(songInfoToMediaItem).toList();
                return Column(
                    children: songs
                            ?.map((MediaItem song) => SongListTile(
                                  song: song,
                                  onTap: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MainPlayerScreen()),
                                    );
                                    await AudioService.updateQueue(
                                        songs.toList());
                                    await AudioService.skipToQueueItem(song.id);
                                    AudioService.play();
                                  },
                                  // selected:
                                  //     (snapshot.data?.currentSource?.tag)
                                  //             ?.filePath ==
                                  //         song.filePath,
                                ))
                            ?.toList() ??
                        []);
              },
            ),
          ],
        ));
  }
}
