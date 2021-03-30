import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/widgets/widgets.dart';

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
    final player = context.read<AudioPlayer>();

    // Un-shuffle the player
    if (AudioService.playbackState.shuffleMode == AudioServiceShuffleMode.all) {
      _reorderSongsToShuffleIndices(player);
    }

    return StreamBuilder<List<MediaItem>>(
        stream: AudioService.queueStream,
        builder: (context, snapshot) {
          final queue = snapshot.data;
          return Scaffold(
            appBar: AppBar(),
            body: StreamBuilder<MediaItem>(
                stream: AudioService.currentMediaItemStream,
                builder: (context, snapshot) {
                  final currentMediaItem = snapshot.data;
                  return ReorderableListView(
                    children: queue
                            ?.toList()
                            ?.map((mediaItem) => SongListTile(
                                  key: Key(mediaItem.id),
                                  song: mediaItem,
                                  draggable: true,
                                  selected:
                                      currentMediaItem?.id == mediaItem.id,
                                ))
                            ?.toList() ??
                        [],
                    onReorder: (int oldIndex, int newIndex) async {
                      // if (oldIndex < newIndex) {
                      //   newIndex -= 1;
                      // }
                      //
                      // final currentlyPlayedIndex = player.currentIndex;
                      // final currentlyPlayedPosition = player.position;
                      // final currentlyPlayedItem = queue[currentlyPlayedIndex];
                      //
                      // final changedItem = queue.removeAt(oldIndex);
                      // queue.insert(newIndex, changedItem);
                      //
                      // await player
                      //     .setAudioSource(ConcatenatingAudioSource(children: queue));
                      // player.seek(currentlyPlayedPosition,
                      //     index: queue.indexOf(currentlyPlayedItem));
                    },
                  );
                }),
          );
        });
  }
}
