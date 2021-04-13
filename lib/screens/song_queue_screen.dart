import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;

class SongQueueScreen extends StatelessWidget {
  /// Player state shouldn't be shuffled (randomized) when you have
  /// seen the song order. (Schrodinger's cat approved :3)
  ///
  /// This method un-shuffles the player and reloads the song
  /// queue in pre-unshuffled order (mainly because it's such a
  /// hassle to deal with song indices all over the place).
  void _reorderSongsToShuffleIndices(AudioPlayer player) async {
    // final newSongOrder = player?.sequenceState?.effectiveSequence;
    // final currentlyPlayedItem = newSongOrder[player.effectiveIndices
    //     .indexWhere((element) => player.currentIndex == element)];
    // final currentlyPlayedPosition = player.position;
    // await player.setShuffleModeEnabled(false);
    // await player
    //     .setAudioSource(ConcatenatingAudioSource(children: newSongOrder));
    // player.seek(currentlyPlayedPosition,
    //     index: newSongOrder.indexOf(currentlyPlayedItem));

    // final newSongOrder = AudioService.queue;
    // final currentlyPlayedItem = AudioService.currentMediaItem;
    // // final currentlyPlayedPosition = AudioService.positionStream;
    // await AudioService.setShuffleMode(AudioServiceShuffleMode.none);
    // await AudioService.updateQueue(newSongOrder);
    // // AudioService.(AudioService.positionStream,
    // //     index: newSongOrder.indexOf(currentlyPlayedItem));
  }

  @override
  Widget build(BuildContext context) {
    // Un-shuffle the player
    if (AudioService.playbackState != null &&
        AudioService.playbackState.shuffleMode == AudioServiceShuffleMode.all) {
      AudioService.customAction('makeShuffledOrderUnshuffledOrder');
    }

    return StreamBuilder<List<MediaItem>>(
        stream: AudioService.queueStream,
        builder: (context, snapshot) {
          final queue = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: Text('Song queue'),
              actions: [
                IconButton(
                    icon: Icon(
                      Icons.cleaning_services,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      AudioService.updateQueue(<MediaItem>[]);
                    })
              ],
            ),
            body: StreamBuilder<MediaItem>(
                stream: AudioService.currentMediaItemStream,
                builder: (context, snapshot) {
                  if (queue == null || queue.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/empty_screen.svg',
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 20.0)),
                          Text(
                            'There are no songs in the queue',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    );
                  }
                  final currentMediaItem = snapshot.data;
                  return ReorderableListView(
                    children: queue
                        .toList()
                        .map(
                          (song) => ListTile(
                            key: UniqueKey(),
                            leading: RoundedImage(
                              image: song.artUri != null
                                  ? ((song.extras ?? {})['isOnline'] ?? false
                                      ? CachedNetworkImageProvider(song.artUri)
                                      : Image.file(
                                              File(Uri.parse(song.artUri).path))
                                          .image)
                                  : AssetImage(Constants.defaultImagePath),
                              width: 50,
                              height: 50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () {
                              AudioService.skipToQueueItem(song.id);
                            },
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: currentMediaItem?.id == song.id,
                            trailing: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.close),
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption
                                          .color,
                                      onPressed: () {
                                        AudioService.removeQueueItem(song);
                                      }),
                                  Container(
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          .color,
                                      size: 36,
                                    ),
                                    padding: EdgeInsets.only(left: 20.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onReorder: (int oldIndex, int newIndex) async {
                      AudioService.customAction(
                          'moveQueueItem', <String, dynamic>{
                        'oldIndex': oldIndex,
                        'newIndex': newIndex,
                      });
                    },
                  );
                }),
          );
        });
  }
}
