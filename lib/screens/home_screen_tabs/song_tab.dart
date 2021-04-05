import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:multi_select_flutter/dialog/mult_select_dialog.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart' as msDialog;
import 'package:multi_select_item/multi_select_item.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../main_player_screen.dart';

class SongTab extends StatefulWidget {
  final List<SongInfo> searchResult;
  final Function(PreferredSizeWidget) tabAppBarCallback;
  final bool reverseOrder;

  const SongTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
    this.tabAppBarCallback,
  })  : this.searchResult =
            searchResult is List<SongInfo> ? searchResult : null,
        super(key: key);

  @override
  _SongTabState createState() => _SongTabState();
}

class _SongTabState extends State<SongTab> {
  final _audioQuery = FlutterAudioQuery();
  final _multiSelectController = MultiSelectController();
  var _songs = <SongInfo>[];

  void _selectAllSongs() {
    setState(() {
      _multiSelectController.selectAll();
    });
    updateParentAppBar();
  }

  void _deselectAllSongs() {
    setState(() {
      _multiSelectController.deselectAll();
    });
    updateParentAppBar();
  }

  void _showDeleteSongsAlert() {
    if (_multiSelectController.selectedIndexes == null &&
        _multiSelectController.selectedIndexes.isEmpty) return;
    final _context = context;
    showDialog(
      context: context,
      builder: (context) {
        final selectedSongs = _multiSelectController.selectedIndexes
            .map((index) => _songs[index])
            .toList();
        return AlertDialog(
          title: Text('Delete songs'),
          content: Text(
              'You\'re about to delete ${selectedSongs.length} songs from your device. This is permanent and can\'t be undone. Do you still want to proceed?'),
          actions: [
            FlatButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FlatButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSongs(selectedSongs);
                _deselectAllSongs();
                showSnackBar(_context,
                    text: 'Deleted ${selectedSongs.length} songs succesfully');
                setState(() {});
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> _deleteSongs(List<SongInfo> songs) async {
    final paths = songs.map((e) => e.filePath).toList();
    try {
      for (String path in paths) {
        File(path).deleteSync();
      }
    } catch (e) {
      print('Delete song error: $e');
    } finally {
      await refreshMediaStore(paths);
      // Wait for a while before refresh song list. This is necessary.
      Timer(Duration(milliseconds: 100), () => setState(() {}));
    }
  }

  Future<void> _addToPlaylists(
      List<SongInfo> songs, List<String> playlistNames) async {
    final playlists = await _audioQuery.getPlaylists();
    for (String playlistName in playlistNames) {
      final playlistSearch = playlists.where((e) => e.name == playlistName);
      if (playlistSearch.isEmpty) return;

      final playlist = playlistSearch.first;
      for (SongInfo song in songs) {
        playlist.addSong(song: song);
      }
    }
  }

  Future<void> _addToQueue(List<SongInfo> songs) async {
    await AudioService.addQueueItems(songs.map(songInfoToMediaItem).toList());
    showSnackBar(context, text: 'Added ${songs.length} songs to queue.');
    _deselectAllSongs();
  }

  Future<void> _addToFavorites(List<SongInfo> songs) async {
    _addToPlaylists(songs, [Constants.favoritesPlaylist]);
    showSnackBar(context, text: 'Added ${songs.length} songs to favorites.');
    _deselectAllSongs();
  }

  void _showPlaylistToAddSongsDialog() {
    final _context = context;
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<PlaylistInfo>>(
            future: _audioQuery.getPlaylists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              final playlists = snapshot.data
                  .where((e) => e.name != Constants.favoritesPlaylist);
              return MultiSelectDialog(
                title: Text('Add to playlists'),
                items: playlists
                    .map((e) => msDialog.MultiSelectItem(e, e.name))
                    .toList(),
                initialValue: [],
                onConfirm: (values) {
                  if (values == null || values.isEmpty) return;
                  for (PlaylistInfo playlist in values) {
                    for (int index in _multiSelectController.selectedIndexes) {
                      playlist.addSong(song: _songs[index]);
                    }
                  }
                  showSnackBar(_context,
                      text:
                          'Added ${_multiSelectController.selectedIndexes.length} songs to playlist(s).');
                  _deselectAllSongs();
                },
                selectedItemsTextStyle: Theme.of(context).textTheme.headline6,
                itemsTextStyle: Theme.of(context).textTheme.headline6,
                checkColor: Theme.of(context).primaryColor,
                selectedColor: Theme.of(context).accentColor,
                unselectedColor: Theme.of(context).textTheme.bodyText1.color,
              );
            });
      },
    );
  }

  void updateParentAppBar() {
    if (_multiSelectController.selectedIndexes.isNotEmpty) {
      widget.tabAppBarCallback(AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _deselectAllSongs,
        ),
        title:
            Text('${_multiSelectController.selectedIndexes.length} selected'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (str) {
              final selectedSongs = _multiSelectController.selectedIndexes
                  .map((index) => _songs[index])
                  .toList();
              switch (str) {
                case 'addToQueue':
                  _addToQueue(selectedSongs);
                  break;
                case 'addToPlaylists':
                  _showPlaylistToAddSongsDialog();
                  break;
                case 'addToFavorites':
                  _addToFavorites(selectedSongs);
                  break;
                case 'selectAll':
                  _selectAllSongs();
                  break;
                case 'delete':
                  _showDeleteSongsAlert();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'addToQueue',
                  child: const Text('Add to Queue'),
                ),
                PopupMenuItem(
                  value: 'addToPlaylists',
                  child: const Text('Add to Playlist(s)...'),
                ),
                PopupMenuItem(
                  value: 'addToFavorites',
                  child: const Text('Add to Favorites'),
                ),
                PopupMenuItem(
                  value: 'selectAll',
                  child: const Text('Select All'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete from Device'),
                )
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
    return FutureBuilder<List<SongInfo>>(
        future: _audioQuery.getSongs(),
        builder: (context, snapshot) {
          final allSongsWithoutSystemMusic = snapshot.data
              ?.where((song) => !song.filePath.contains(r'/Android/media/'))
              ?.toList();
          _songs = widget.searchResult ?? allSongsWithoutSystemMusic;
          if (_songs == null || _songs.isEmpty) {
            return NullTab();
          }
          if (!_multiSelectController.isSelecting) {
            _multiSelectController.set(_songs.length);
          }
          return ListView.builder(
              itemCount: _songs.length,
              reverse: widget.reverseOrder,
              itemBuilder: (BuildContext context, int index) {
                return MultiSelectItem(
                  isSelecting: _multiSelectController.isSelecting,
                  onSelected: () {
                    setState(() {
                      _multiSelectController.toggle(index);
                    });
                    updateParentAppBar();
                  },
                  child: Container(
                    child: SongListTile(
                      song: songInfoToMediaItem(_songs[index]),
                      onTap: () async {
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
                              builder: (context) => MainPlayerScreen()),
                        );
                        await AudioService.updateQueue(
                            _songs.map(songInfoToMediaItem).toList());
                        await AudioService.skipToQueueItem(_songs[index].id);
                        AudioService.play();
                      },
                    ),
                    decoration: _multiSelectController.isSelected(index)
                        ? new BoxDecoration(color: Colors.red[300])
                        : null,
                  ),
                );
              });
        });
  }
}
