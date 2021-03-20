import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';

class SongQueueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();

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

                var currentlyPlayedIndex = player.currentIndex;
                var currentlyPlayedPosition = player.position;

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
