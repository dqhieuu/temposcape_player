import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:http/http.dart' as http;
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

class AlbumScreen extends StatefulWidget {
  final AlbumInfo albumInput;

  const AlbumScreen({Key key, this.albumInput}) : super(key: key);

  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final audioQuery = FlutterAudioQuery();

  var songs = <SongInfo>[];

  @override
  Widget build(BuildContext context) {
    final albumArt = widget.albumInput.albumArt != null
        ? Image.file(File(widget.albumInput.albumArt)).image
        : AssetImage(Constants.defaultAlbumPath);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.albumInput.title),
        ),
        body: FutureBuilder<http.Response>(
            future: http.get(
                'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=${Constants.lastFmApiKey}&artist=${widget.albumInput.artist.replaceAll(' ', '+')}&album=${widget.albumInput.title.replaceAll(' ', '+')}&format=json'),
            builder: (context, snapshot) {
              var album;
              if (snapshot.hasData) {
                album = json.decode(snapshot.data.body)['album'];
              }
              return ListView(
                children: [
                  ArtCoverHeader(
                    height: 200,
                    image: albumArt,
                    content: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoundedImage(
                            image: albumArt,
                            width: 140,
                            height: 140,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.albumInput.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Padding(padding: EdgeInsets.only(bottom: 8)),
                                  Text(
                                    widget.albumInput.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption
                                          .color,
                                    ),
                                  ),
                                  Spacer(),
                                  if (album != null &&
                                      album['playcount'] != null)
                                    Text('Play count: ${album['playcount']}'),
                                  if (album != null &&
                                      album['listeners'] != null)
                                    Text('Listeners: ${album['listeners']}'),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [],
                    ),
                  ),
                  if (album != null && (album['wiki'] ?? {})['content'] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ExpandableText(
                        '${album['wiki']['content']}',
                        expandText: 'show more',
                        collapseText: 'show less',
                        maxLines: 3,
                        linkColor: Colors.blue,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Tracks',
                          style: TextStyle(fontSize: 24),
                        ),
                        Divider()
                      ],
                    ),
                  ),
                  StreamBuilder<MediaItem>(
                      stream: AudioService.currentMediaItemStream,
                      builder: (context, snapshot) {
                        final currentMediaItem = snapshot.data;
                        return FutureBuilder<List<SongInfo>>(
                          future: audioQuery.getSongsFromAlbum(
                              albumId: widget.albumInput.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return Container();
                            final songs =
                                snapshot.data.map(songInfoToMediaItem).toList();
                            return Column(
                                children: songs
                                        ?.map(
                                          (MediaItem song) => ListTile(
                                            leading: Text(
                                                (songs.indexOf(song) + 1)
                                                    .toString()
                                                    .padLeft(2, "0"),
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .caption
                                                      .color,
                                                )),
                                            title: Text(
                                              song.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Text(
                                              getFormattedDuration(
                                                  song.duration,
                                                  timeFormat: TimeFormat
                                                      .optionalHoursMinutes0Seconds),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .caption
                                                    .color,
                                              ),
                                            ),
                                            onTap: () async {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MainPlayerScreen()),
                                              );
                                              await AudioService.updateQueue(
                                                  songs.toList());
                                              await AudioService
                                                  .skipToQueueItem(song.id);
                                              AudioService.play();
                                            },
                                            selected:
                                                currentMediaItem?.id == song.id,
                                          ),
                                        )
                                        ?.toList() ??
                                    []);
                          },
                        );
                      }),
                  SizedBox(height: 60),
                ],
              );
            }));
  }
}
