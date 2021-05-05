import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;

class SongQueueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Un-shuffle the player to previously shuffled position for less complexity
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
                  icon: Icon(Icons.cleaning_services_rounded),
                  onPressed: queue?.isNotEmpty ?? false
                      ? () {
                          AudioService.updateQueue(<MediaItem>[]);
                        }
                      : null,
                )
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
                          NullTabWithCustomText(
                              'There are no songs in the queue'),
                        ],
                      ),
                    );
                  }
                  final currentMediaItem = snapshot.data;
                  return ReorderableListView(
                    children: queue
                        .toList()
                        .map(
                          (song) =>
                              buildListTile(song, currentMediaItem, context),
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

  Widget buildListTile(
      MediaItem song, MediaItem currentMediaItem, BuildContext context) {
    return ListTile(
      key: UniqueKey(),
      leading: RoundedImage(
        image: song.artUri != null
            ? ((song.extras ?? {})['isOnline'] ?? false
                ? CachedNetworkImageProvider(song.artUri)
                : Image.file(File(Uri.parse(song.artUri).path)).image)
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
      selected: currentMediaItem == song,
      trailing: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: Icon(Icons.close),
                color: Theme.of(context).textTheme.caption.color,
                onPressed: () {
                  AudioService.removeQueueItem(song);
                }),
            Container(
              child: Icon(
                Icons.drag_handle_rounded,
                color: Theme.of(context).textTheme.bodyText1.color,
                size: 36,
              ),
              padding: EdgeInsets.only(left: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
