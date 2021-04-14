import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:temposcape_player/utils/song_type_conversion.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../../constants/constants.dart' as Constants;
import '../main_player_screen.dart';

class FavoriteTab extends StatefulWidget {
  final List<SongInfo> searchResult;
  final bool reverseOrder;
  final Function(PreferredSizeWidget) tabAppBarCallback;

  const FavoriteTab({
    Key key,
    List searchResult,
    this.reverseOrder = false,
    this.tabAppBarCallback,
  })  : this.searchResult =
            searchResult is List<SongInfo> ? searchResult : null,
        super(key: key);

  @override
  _FavoriteTabState createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
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

  void _removeFromFavorites(List<SongInfo> songs) async {
    final favoritesPlaylist = (await _audioQuery.getPlaylists())
        ?.where((element) => element.name == Constants.favoritesPlaylistHiveBox)
        ?.first;
    if (favoritesPlaylist == null) return;
    for (SongInfo song in songs) {
      favoritesPlaylist.removeSong(song: song);
    }
    setState(() {});
  }

  Future<void> _addToQueue(List<SongInfo> songs) async {
    await AudioService.addQueueItems(songs.map(songInfoToMediaItem).toList());
    showSnackBar(context, text: 'Added ${songs.length} songs to queue.');
    _deselectAllSongs();
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
                case 'removeFromFavorites':
                  _removeFromFavorites(selectedSongs);
                  _deselectAllSongs();
                  break;
                case 'addToQueue':
                  _addToQueue(selectedSongs);
                  break;
                case 'selectAll':
                  _selectAllSongs();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'removeFromFavorites',
                  child: const Text('Remove from Favorites'),
                ),
                PopupMenuItem(
                  value: 'addToQueue',
                  child: const Text('Add to Queue'),
                ),
                PopupMenuItem(
                  value: 'selectAll',
                  child: const Text('Select all'),
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

  Widget _buildNullPlaylist() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NullTabCustomText('You have 0 favorite songs'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistInfo>>(
        future: _audioQuery.getPlaylists(),
        builder: (context, snapshot) {
          final favoritesPlaylist = snapshot.data
              ?.where((element) =>
                  element.name == Constants.favoritesPlaylistHiveBox)
              ?.first;
          if (favoritesPlaylist == null) {
            return _buildNullPlaylist();
          }
          return FutureBuilder<List<SongInfo>>(
              future:
                  _audioQuery.getSongsFromPlaylist(playlist: favoritesPlaylist),
              builder: (context, snapshot) {
                _songs = widget.searchResult ?? snapshot.data;
                if (_songs == null || _songs.isEmpty) {
                  return _buildNullPlaylist();
                }
                if (!_multiSelectController.isSelecting) {
                  _multiSelectController.set(_songs.length);
                }
                return StreamBuilder<MediaItem>(
                    stream: AudioService.currentMediaItemStream,
                    builder: (context, snapshot) {
                      final currentMediaItem = snapshot.data;
                      return ListView.builder(
                        itemCount: _songs.length,
                        reverse: widget.reverseOrder,
                        itemBuilder: (_, index) {
                          final song = _songs[index];
                          return Container(
                            child: MultiSelectItem(
                              isSelecting: _multiSelectController.isSelecting,
                              onSelected: () {
                                setState(() {
                                  _multiSelectController.toggle(index);
                                });
                                updateParentAppBar();
                              },
                              child: SongListTile(
                                song: songInfoToMediaItem(song),
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
                                        builder: (context) =>
                                            MainPlayerScreen()),
                                  );
                                  await AudioService.updateQueue(
                                      _songs.map(songInfoToMediaItem).toList());
                                  await AudioService.skipToQueueItem(song.id);
                                  AudioService.play();
                                },
                                selected: currentMediaItem?.id == song.id,
                              ),
                            ),
                            decoration: _multiSelectController.isSelected(index)
                                ? new BoxDecoration(
                                    color: Theme.of(context)
                                        .accentColor
                                        .withOpacity(0.4),
                                  )
                                : null,
                          );
                        },
                      );
                    });
              });
        });
  }
}
