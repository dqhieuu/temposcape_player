import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/utils/song_type_conversion.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

class GenreScreen extends StatefulWidget {
  final GenreInfo genreInput;

  const GenreScreen({Key key, this.genreInput}) : super(key: key);

  @override
  _GenreScreenState createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  final _audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            // title: Text(widget.genreInput.name),
            ),
        body: ListView(
          children: [
            ArtCoverHeader(
              height: 220,
              image: AssetImage(Constants.defaultImagePath),
              content: Row(
                children: [
                  Image(
                    image: AssetImage(Constants.defaultImagePath),
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
                        // Text(
                        //   widget.genreInput.name,
                        //   maxLines: 2,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Text('Tracks'),
            FutureBuilder<List<SongInfo>>(
              future:
                  _audioQuery.getSongsFromGenre(genre: widget.genreInput.name),
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
