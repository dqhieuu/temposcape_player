import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:hive/hive.dart';
import 'package:temposcape_player/models/artist_cache.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../artists_screen.dart';

class ArtistTab extends StatefulWidget {
  final List<ArtistInfo> searchResult;

  const ArtistTab({Key key, List searchResult})
      : this.searchResult =
            searchResult is List<ArtistInfo> ? searchResult : null,
        super(key: key);

  @override
  _ArtistTabState createState() => _ArtistTabState();
}

class _ArtistTabState extends State<ArtistTab> {
  final _audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArtistInfo>>(
        future: _audioQuery.getArtists(),
        builder: (context, snapshot) {
          final artists = widget.searchResult ?? snapshot.data;
          if (artists == null || artists.isEmpty) {
            return NullTab();
          }
          return GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 0.55,
            children: artists.map((ArtistInfo artist) {
              ImageProvider artistImage;
              final cachedImage = Hive.box<ArtistCache>(ArtistCache.hiveBox)
                  .get(artist.id)
                  ?.imageBinary;
              if (cachedImage != null) {
                artistImage = Image.memory(cachedImage).image;
              } else if (artist.artistArtPath != null) {
                artistImage = Image.file(File(artist.artistArtPath)).image;
              } else {
                artistImage = AssetImage(Constants.defaultImagePath);
              }
              return MyGridTile(
                child: Column(children: [
                  AspectRatio(
                    aspectRatio: 0.7,
                    child: Image(
                      image: artistImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    artist.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ]),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ArtistScreen(artistInput: artist)));
                },
              );
            }).toList(),
          );
        });
  }
}
