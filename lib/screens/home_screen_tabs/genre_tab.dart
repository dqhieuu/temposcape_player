import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;

class GenreTab extends StatefulWidget {
  final List<GenreInfo> searchResult;
  final bool reverseOrder;

  const GenreTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
  })  : this.searchResult =
            searchResult is List<GenreInfo> ? searchResult : null,
        super(key: key);

  @override
  _GenreTabState createState() => _GenreTabState();
}

class _GenreTabState extends State<GenreTab> {
  final _audioQuery = FlutterAudioQuery();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GenreInfo>>(
        future: _audioQuery.getGenres(),
        builder: (context, snapshot) {
          final genres = widget.searchResult ?? snapshot.data;
          if (genres == null || genres.isEmpty) {
            return NullTab();
          }
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.3,
            ),
            itemCount: genres.length,
            reverse: widget.reverseOrder,
            itemBuilder: (_, index) {
              final genre = genres[index];
              final genreImagePath = Constants.genreImagePaths[
                  genres.indexOf(genre) % Constants.genreImagePaths.length];
              return MyGridTile(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) => GenreScreen(genreInput: genre)),
                  // );
                },
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.7,
                      child: Image(
                        image: AssetImage(genreImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      genre.name,
                      maxLines: 1,
                    )
                  ],
                ),
              );
            },
          );
        });
  }
}
