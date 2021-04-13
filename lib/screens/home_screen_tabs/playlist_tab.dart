import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:hive/hive.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:temposcape_player/screens/playlist_screen.dart';
import 'package:temposcape_player/utils/utils.dart';
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
  final _playlistNamesBox = Hive.box<String>(Constants.playlistNamesHiveBox);
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

  void _showRenamePlaylistDialog(PlaylistInfo playlist) {
    showDialog(
      context: context,
      builder: (context) {
        final myController = TextEditingController();
        return AlertDialog(
          title: Text('Rename playlist'),
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
                await _playlistNamesBox.put(playlist.name, myController.text);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Rename'),
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
      _playlistNamesBox.delete(playlist.name);
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
                case 'renamePlaylist':
                  _showRenamePlaylistDialog(selectedPlaylists.first);
                  _deselectAllPlaylists();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                if (_multiSelectController.selectedIndexes.length == 1)
                  PopupMenuItem(
                    value: 'renamePlaylist',
                    child: const Text('Rename playlist...'),
                  ),
                PopupMenuItem(
                  value: 'emptyPlaylists',
                  child: const Text('Empty playlist(s)'),
                ),
                PopupMenuItem(
                  value: 'deletePlaylists',
                  child: const Text('Delete playlist(s)'),
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
            ?.where((playlist) =>
                playlist.name != Constants.favoritesPlaylistHiveBox)
            ?.toList();
        if (_playlists == null || _playlists.isEmpty) {
          return Center(
            child: GestureDetector(
              onTap: _showAddPlaylistDialog,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Icon(
                      CupertinoIcons.rectangle_stack_badge_plus,
                      size: 64,
                      color: Theme.of(context).textTheme.caption.color,
                    ),
                  ),
                  Text(
                    'Add a playlist...',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.caption.color,
                    ),
                  ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    title: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        playlistName(playlist),
                        maxLines: 1,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
                    ? new BoxDecoration(
                        color: Theme.of(context).accentColor.withOpacity(0.4))
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
