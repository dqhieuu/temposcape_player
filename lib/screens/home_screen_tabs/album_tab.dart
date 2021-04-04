import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../album_screen.dart';

class AlbumTab extends StatefulWidget {
  final List<AlbumInfo> searchResult;

  const AlbumTab({Key key, List searchResult})
      : this.searchResult =
            searchResult is List<AlbumInfo> ? searchResult : null,
        super(key: key);

  @override
  _AlbumTabState createState() => _AlbumTabState();
}

class _AlbumTabState extends State<AlbumTab> {
  final _audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlbumInfo>>(
        future: _audioQuery.getAlbums(),
        builder: (context, snapshot) {
          final albums = widget.searchResult ?? snapshot.data;
          if (albums == null || albums.isEmpty) {
            return NullTab();
          }
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? 3
                        : 5,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.75,
              ),
              itemCount: albums.length,
              itemBuilder: (_, int index) {
                final album = albums[index];
                return MyGridTile(
                  child: Column(
                    children: [
                      albums[index].albumArt != null
                          ? Image.file(File(album.albumArt))
                          : Image(
                              image: AssetImage(Constants.defaultAlbumPath),
                            ),
                      Text(
                        album.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      )
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AlbumScreen(
                                  albumInput: album,
                                )));
                  },
                );
              });
        });
  }
}
