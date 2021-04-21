import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:temposcape_player/utils/song_type_conversion.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final PlaylistInfo playlistInput;

  const PlaylistScreen({Key key, this.playlistInput}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _audioQuery = FlutterAudioQuery();
  final _multiSelectController = MultiSelectController();
  var _songs = <SongInfo>[];

  void _selectAllSongs() {
    setState(() {
      _multiSelectController.selectAll();
    });
  }

  void _deselectAllSongs() {
    setState(() {
      _multiSelectController.deselectAll();
    });
  }

  Future<void> _removeFromPlaylist(List<SongInfo> songs) async {
    for (SongInfo song in songs) {
      await widget.playlistInput.removeSong(song: song);
    }
    setState(() {});
  }

  Future<void> _addToQueue(List<SongInfo> songs) async {
    await AudioService.addQueueItems(songs.map(songInfoToMediaItem).toList());
    _deselectAllSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 160.0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _multiSelectController.isSelecting
                  ? '${_multiSelectController.selectedIndexes.length} selected'
                  : playlistName(widget.playlistInput),
            ),
            background: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Image(
                image: AssetImage(
                  Constants.playlistBgPath,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          actions: [
            if (_multiSelectController.isSelecting)
              PopupMenuButton<String>(
                onSelected: (str) {
                  final selectedSongs = _multiSelectController.selectedIndexes
                      .map((index) => _songs[index])
                      .toList();
                  switch (str) {
                    case 'removeFromPlaylist':
                      _removeFromPlaylist(selectedSongs);
                      _deselectAllSongs();
                      break;
                    case 'addToQueue':
                      _addToQueue(selectedSongs);
                      _deselectAllSongs();
                      break;
                    case 'selectAll':
                      _selectAllSongs();
                      break;
                    case 'deselectAll':
                      _deselectAllSongs();
                      break;
                  }
                },
                itemBuilder: (_) {
                  return [
                    PopupMenuItem(
                      value: 'removeFromPlaylist',
                      child: const Text('Remove from Playlist'),
                    ),
                    PopupMenuItem(
                      value: 'addToQueue',
                      child: const Text('Add to Queue'),
                    ),
                    PopupMenuItem(
                      value: 'selectAll',
                      child: const Text('Select all'),
                    ),
                    PopupMenuItem(
                      value: 'deselectAll',
                      child: const Text('Deselect all'),
                    ),
                  ];
                },
              )
          ],
        ),
        FutureBuilder<List<SongInfo>>(
            future: _audioQuery.getSongsFromPlaylist(
                playlist: widget.playlistInput),
            builder: (context, snapshot) {
              _songs = snapshot.data?.toList();

              if (_songs == null || _songs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          NullTabWithCustomText(
                              'There are no songs in this playlist'),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (!_multiSelectController.isSelecting) {
                _multiSelectController.set(_songs.length);
              }
              return StreamBuilder<MediaItem>(
                stream: AudioService.currentMediaItemStream,
                builder: (context, snapshot) {
                  final currentMediaItem = snapshot.data;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, int index) => Container(
                        child: MultiSelectItem(
                          isSelecting: _multiSelectController.isSelecting,
                          onSelected: () {
                            setState(() {
                              _multiSelectController.toggle(index);
                            });
                          },
                          child: SongListTile(
                            song: songInfoToMediaItem(_songs[index]),
                            onTap: () async {
                              if (_multiSelectController.isSelecting) {
                                setState(() {
                                  _multiSelectController.toggle(index);
                                });
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainPlayerScreen()),
                              );
                              await AudioService.updateQueue(
                                  _songs.map(songInfoToMediaItem).toList());
                              await AudioService.skipToQueueItem(
                                  _songs[index].id);
                              AudioService.play();
                            },
                            selected: currentMediaItem?.id == _songs[index].id,
                          ),
                        ),
                        decoration: _multiSelectController.isSelected(index)
                            ? new BoxDecoration(
                                color: Theme.of(context)
                                    .accentColor
                                    .withOpacity(0.4))
                            : null,
                      ),
                      childCount: _songs.length,
                    ),
                  );
                },
              );
            })
      ],
    ));
  }
}
