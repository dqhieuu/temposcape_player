import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../album_screen.dart';

class AlbumTab extends StatefulWidget {
  final List<AlbumInfo> searchResult;
  final bool reverseOrder;

  const AlbumTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
  })  : this.searchResult =
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
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).orientation == Orientation.portrait
                          ? 3
                          : 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.73,
                ),
                reverse: widget.reverseOrder,
                itemCount: albums.length,
                itemBuilder: (_, int index) {
                  final album = albums[index];
                  return GestureDetector(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: RoundedImage(
                            image: album.albumArt != null
                                ? Image.file(File(album.albumArt)).image
                                : AssetImage(Constants.defaultAlbumPath),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Text(
                          album.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
                }),
          );
        });
  }
}
