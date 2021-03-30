import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../main_player_screen.dart';

class SongTab extends StatefulWidget {
  final List<SongInfo> searchResult;

  const SongTab({Key key, List searchResult})
      : this.searchResult =
            searchResult is List<SongInfo> ? searchResult : null,
        super(key: key);

  @override
  _SongTabState createState() => _SongTabState();
}

class _SongTabState extends State<SongTab> {
  final _audioQuery = FlutterAudioQuery();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongInfo>>(
        future: _audioQuery.getSongs(),
        builder: (context, snapshot) {
          final allSongsWithoutSystemMusic = snapshot.data
              ?.where((song) => !song.filePath.contains(r'/Android/media/'))
              ?.toList();
          final songs = widget.searchResult ?? allSongsWithoutSystemMusic;
          if (songs == null || songs.isEmpty) {
            return NullTab();
          }
          return ListView(
              children: songs
                  .map((SongInfo song) => SongListTile(
                        song: songInfoToMediaItem(song),
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MainPlayerScreen()),
                          );
                          await AudioService.updateQueue(
                              songs.map(songInfoToMediaItem).toList());
                          await AudioService.skipToQueueItem(song.id);
                          AudioService.play();
                        },
                      ))
                  .toList());
        });
  }
}
