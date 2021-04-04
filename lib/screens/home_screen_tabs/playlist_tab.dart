import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:temposcape_player/screens/playlist_screen.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;

class PlaylistTab extends StatefulWidget {
  final List<PlaylistInfo> searchResult;

  const PlaylistTab({Key key, List searchResult})
      : this.searchResult =
            searchResult is List<PlaylistInfo> ? searchResult : null,
        super(key: key);

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  final _audioQuery = FlutterAudioQuery();

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final myController = TextEditingController();
        return AlertDialog(
          title: Text('Add playlist'),
          content: TextField(
            controller: myController,
            decoration: InputDecoration(
              labelText: "Title",
            ),
          ),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FlatButton(
              onPressed: () async {
                await FlutterAudioQuery.createPlaylist(
                    playlistName: myController.text);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistInfo>>(
      future: _audioQuery.getPlaylists(),
      builder: (context, snapshot) {
        final playlists = (widget.searchResult ?? snapshot.data)
            ?.where((playlist) => playlist.name != Constants.favoritesPlaylist)
            ?.toList();
        if (playlists == null || playlists.isEmpty) {
          return Center(
            child: GestureDetector(
              onTap: _showAddPlaylistDialog,
              child: Column(
                children: [
                  IconButton(icon: Icon(Icons.add), onPressed: null),
                  Text('Add a playlist here'),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: _showAddPlaylistDialog,
          ),
          body: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (BuildContext context, int index) {
              final playlist = playlists[index];
              return ListTile(
                leading: RoundedImage(
                  image: AssetImage(Constants.defaultImagePath),
                  width: 50,
                  height: 50,
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                ),
                subtitle: Text(
                    'Total songs: ${playlist.memberIds.length.toString()}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PlaylistScreen(playlistInput: playlist)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
