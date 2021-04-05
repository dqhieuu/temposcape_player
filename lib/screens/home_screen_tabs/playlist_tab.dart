import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:temposcape_player/screens/playlist_screen.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;

class PlaylistTab extends StatefulWidget {
  final List<PlaylistInfo> searchResult;
  final bool reverseOrder;
  final Function(PreferredSizeWidget) tabAppBarCallback;

  const PlaylistTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
    this.tabAppBarCallback,
  })  : this.searchResult =
            searchResult is List<PlaylistInfo> ? searchResult : null,
        super(key: key);

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  final _audioQuery = FlutterAudioQuery();
  final _multiSelectController = MultiSelectController();
  var _playlists = <PlaylistInfo>[];

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
              labelText: "Name",
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

  void _deselectAllPlaylists() {
    setState(() {
      _multiSelectController.deselectAll();
    });
    updateParentAppBar();
  }

  void _emptyPlaylists(List<PlaylistInfo> playlists) async {
    for (PlaylistInfo playlist in playlists) {
      final playlistName = playlist.name;
      await FlutterAudioQuery.removePlaylist(playlist: playlist);
      FlutterAudioQuery.createPlaylist(playlistName: playlistName);
    }
    setState(() {});
  }

  void _deletePlaylists(List<PlaylistInfo> playlists) {
    for (PlaylistInfo playlist in playlists) {
      FlutterAudioQuery.removePlaylist(playlist: playlist);
    }
    setState(() {});
  }

  void updateParentAppBar() {
    if (_multiSelectController.selectedIndexes.isNotEmpty) {
      widget.tabAppBarCallback(AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _deselectAllPlaylists,
        ),
        title:
            Text('${_multiSelectController.selectedIndexes.length} selected'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (str) {
              final selectedPlaylists = _multiSelectController.selectedIndexes
                  .map((index) => _playlists[index])
                  .toList();
              switch (str) {
                case 'emptyPlaylists':
                  _emptyPlaylists(selectedPlaylists);
                  _deselectAllPlaylists();
                  break;
                case 'deletePlaylists':
                  _deletePlaylists(selectedPlaylists);
                  _deselectAllPlaylists();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'emptyPlaylists',
                  child: const Text('Empty playlists'),
                ),
                PopupMenuItem(
                  value: 'deletePlaylists',
                  child: const Text('Delete playlists'),
                ),
              ];
            },
          )
        ],
      ));
    } else {
      widget.tabAppBarCallback(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistInfo>>(
      future: _audioQuery.getPlaylists(),
      builder: (context, snapshot) {
        _playlists = (widget.searchResult ?? snapshot.data)
            ?.where((playlist) => playlist.name != Constants.favoritesPlaylist)
            ?.toList();
        if (_playlists == null || _playlists.isEmpty) {
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
        if (!_multiSelectController.isSelecting) {
          _multiSelectController.set(_playlists.length);
        }
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: _showAddPlaylistDialog,
          ),
          body: ListView.builder(
            reverse: widget.reverseOrder,
            itemCount: _playlists.length,
            itemBuilder: (BuildContext context, int index) {
              final playlist = _playlists[index];
              return Container(
                child: MultiSelectItem(
                  isSelecting: _multiSelectController.isSelecting,
                  onSelected: () {
                    setState(() {
                      _multiSelectController.toggle(index);
                    });
                    updateParentAppBar();
                  },
                  child: ListTile(
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
                      if (_multiSelectController.isSelecting) {
                        setState(() {
                          _multiSelectController.toggle(index);
                        });
                        updateParentAppBar();
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PlaylistScreen(playlistInput: playlist)),
                      );
                    },
                  ),
                ),
                decoration: _multiSelectController.isSelected(index)
                    ? new BoxDecoration(color: Colors.red[300])
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
