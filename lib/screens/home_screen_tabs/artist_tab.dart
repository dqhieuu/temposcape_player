import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:hive/hive.dart';
import 'package:temposcape_player/models/artist_cache.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../artist_screen.dart';

class ArtistTab extends StatefulWidget {
  final List<ArtistInfo> searchResult;
  final bool reverseOrder;

  const ArtistTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
  })  : this.searchResult =
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
                childAspectRatio: 0.55,
              ),
              reverse: widget.reverseOrder,
              itemCount: artists.length,
              itemBuilder: (_, index) {
                final artist = artists[index];
                ImageProvider artistImage;
                final cachedImage = Hive.box<ArtistCache>(ArtistCache.hiveBox)
                    .get(artist.id)
                    ?.imageBinary;
                if (cachedImage != null) {
                  artistImage = Image.memory(cachedImage).image;
                } else if (artist.artistArtPath != null) {
                  artistImage = Image.file(File(artist.artistArtPath)).image;
                } else {
                  artistImage = AssetImage(Constants.defaultArtistPath);
                }
                return buildArtistTile(artistImage, artist, context);
              },
            ),
          );
        });
  }

  Widget buildArtistTile(ImageProvider<Object> artistImage, ArtistInfo artist,
      BuildContext context) {
    return GestureDetector(
      child: Column(children: [
        AspectRatio(
          aspectRatio: 0.7,
          child: RoundedImage(
            image: artistImage,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Text(artist.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
      ]),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ArtistScreen(artistInput: artist)));
      },
    );
  }
}
