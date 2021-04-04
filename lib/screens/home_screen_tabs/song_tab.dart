import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
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
  var songs = <SongInfo>[];

  void addToFavorite(List<SongInfo> songs) {}

  void selectAllSongs() {
    setState(() {
      _multiSelectController.selectAll();
    });
    updateParentAppBar();
  }

  void deselectAllSongs() {
    setState(() {
      _multiSelectController.deselectAll();
    });
    updateParentAppBar();
  }

  Future<void> deleteSongs(List<SongInfo> songs) async {
    final paths = songs.map((e) => e.filePath).toList();
    try {
      for (String path in paths) {
        File(path).deleteSync();
      }
    } catch (e) {
      print('Delete song error: $e');
    } finally {
      await refreshMediaStore(paths);
      deselectAllSongs();
      // Wait for a while before refresh song list. This is necessary.
      Timer(Duration(milliseconds: 100), () => setState(() {}));
    }
  }

  Future<void> addToPlaylists(
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

  Future<void> addToFavorites(List<SongInfo> songs) async {
    addToPlaylists(songs, [Constants.favoritesPlaylist]);
    deselectAllSongs();
  }

  void updateParentAppBar() {
    if (_multiSelectController.selectedIndexes.isNotEmpty) {
      widget.tabAppBarCallback(AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: deselectAllSongs,
        ),
        title:
            Text('${_multiSelectController.selectedIndexes.length} selected'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (str) {
              final selectedSongs = _multiSelectController.selectedIndexes
                  .map((index) => songs[index])
                  .toList();
              switch (str) {
                case 'addToPlaylist':
                  break;
                case 'addToFavorites':
                  addToFavorites(selectedSongs);
                  break;
                case 'selectAll':
                  selectAllSongs();
                  break;
                case 'delete':
                  deleteSongs(selectedSongs);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'addToPlaylist',
                  child: const Text('Add to Queue'),
                ),
                PopupMenuItem(
                  value: 'addToPlaylist',
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
          songs = widget.searchResult ?? allSongsWithoutSystemMusic;
          if (songs == null || songs.isEmpty) {
            return NullTab();
          }
          if (!_multiSelectController.isSelecting) {
            _multiSelectController.set(songs.length);
          }
          return ListView.builder(
              itemCount: songs.length,
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
                      song: songInfoToMediaItem(songs[index]),
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
                            songs.map(songInfoToMediaItem).toList());
                        await AudioService.skipToQueueItem(songs[index].id);
                        AudioService.play();
                      },
                    ),
                    decoration: _multiSelectController.isSelected(index)
                        ? new BoxDecoration(color: Colors.red[300])
                        : new BoxDecoration(),
                  ),
                );
              });
        });
  }
}
