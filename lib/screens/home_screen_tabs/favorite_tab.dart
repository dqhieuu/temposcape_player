import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/utils/song_type_conversion.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../main_player_screen.dart';

class FavoriteTab extends StatefulWidget {
  final List<SongInfo> searchResult;

  const FavoriteTab({Key key, List searchResult})
      : this.searchResult =
            searchResult is List<SongInfo> ? searchResult : null,
        super(key: key);

  @override
  _FavoriteTabState createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  final _audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistInfo>>(
        future: _audioQuery.getPlaylists(),
        builder: (context, snapshot) {
          final favoritesPlaylist = snapshot.data
              ?.where((element) => element.name == Constants.favoritesPlaylist)
              ?.first;
          if (favoritesPlaylist == null) {
            return NullTab();
          }
          return FutureBuilder<List<SongInfo>>(
              future:
                  _audioQuery.getSongsFromPlaylist(playlist: favoritesPlaylist),
              builder: (context, snapshot) {
                final allSongsWithoutSystemMusic = snapshot.data
                    ?.where(
                        (song) => !song.filePath.contains(r'/Android/media/'))
                    ?.toList();
                final songs = widget.searchResult ?? allSongsWithoutSystemMusic;
                if (songs == null || songs.isEmpty) {
                  return NullTab();
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (_, index) {
                    final song = songs[index];
                    return SongListTile(
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
                      // selected:
                      //     (snapshot.data?.currentSource?.tag)
                      //             ?.filePath ==
                      //         song.filePath,
                    );
                  },
                );
              });
        });
  }
}
