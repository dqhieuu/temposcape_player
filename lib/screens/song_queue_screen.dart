import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';

class SongQueueScreen extends StatelessWidget {
  /// Player state shouldn't be shuffled (randomized) when you have
  /// seen the song order. (Schrodinger's cat approved :3)
  ///
  /// This method un-shuffles the player and reloads the song
  /// queue in pre-unshuffled order (mainly because it's such a
  /// hassle to deal with song indices all over the place).
  void _reorderSongsToShuffleIndices(AudioPlayer player) async {
    final newSongOrder = player?.sequenceState?.effectiveSequence;
    final currentlyPlayedItem = newSongOrder[player.effectiveIndices
        .indexWhere((element) => player.currentIndex == element)];
    final currentlyPlayedPosition = player.position;
    await player.setShuffleModeEnabled(false);
    await player
        .setAudioSource(ConcatenatingAudioSource(children: newSongOrder));
    player.seek(currentlyPlayedPosition,
        index: newSongOrder.indexOf(currentlyPlayedItem));
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();

    // Un-shuffle the player
    if (player.shuffleModeEnabled) {
      _reorderSongsToShuffleIndices(player);
    }

    return StreamBuilder<SequenceState>(
        stream: player.sequenceStateStream,
        builder: (context, snapshot) {
          final queue = snapshot.data?.effectiveSequence;
          return Scaffold(
            appBar: AppBar(),
            body: ReorderableListView(
              children: queue
                      ?.toList()
                      ?.map((IndexedAudioSource song) => SongListTile(
                            key: Key(song.tag.id),
                            song: song.tag,
                            draggable: true,
                            selected:
                                (snapshot.data?.currentSource?.tag as SongInfo)
                                        ?.filePath ==
                                    (song.tag as SongInfo).filePath,
                          ))
                      ?.toList() ??
                  [],
              onReorder: (int oldIndex, int newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final currentlyPlayedIndex = player.currentIndex;
                final currentlyPlayedPosition = player.position;
                final currentlyPlayedItem = queue[currentlyPlayedIndex];

                final changedItem = queue.removeAt(oldIndex);
                queue.insert(newIndex, changedItem);

                await player
                    .setAudioSource(ConcatenatingAudioSource(children: queue));
                player.seek(currentlyPlayedPosition,
                    index: queue.indexOf(currentlyPlayedItem));
              },
              // onReorder: (int _, int __) {},
            ),
          );
        });
  }
}
