import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:hive/hive.dart';
import 'package:scrobblenaut/lastfm.dart' as lastfm;
import 'package:scrobblenaut/scrobblenaut.dart' as scrobblenaut;
import 'package:temposcape_player/models/artist_cache.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'album_screen.dart';
import 'main_player_screen.dart';

class ArtistScreen extends StatefulWidget {
  final ArtistInfo artistInput;

  const ArtistScreen({Key key, this.artistInput}) : super(key: key);

  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final audioQuery = FlutterAudioQuery();
  final cacheBox = Hive.box<ArtistCache>(ArtistCache.hiveBox);

  var songs = <SongInfo>[];

  Future<void> _addArtistToCache(String key, lastfm.Artist artistInfo) async {
    final artistImageUrl = artistInfo?.images?.first?.text;
    cacheBox.put(
        key,
        ArtistCache(
          bioSummary: artistInfo.bio?.summary,
          bioFull: artistInfo.bio?.content,
          imageBinary: artistImageUrl != null
              ? (await NetworkAssetBundle(Uri.parse(artistImageUrl))
                      .load(artistImageUrl))
                  .buffer
                  .asUint8List()
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.artistInput.name),
        ),
        body: FutureBuilder<lastfm.Artist>(
            future: scrobblenaut.Scrobblenaut.instance.artist
                .getInfo(artist: widget.artistInput.name),
            builder: (context, snapshot) {
              final ArtistCache artistCache =
                  cacheBox.get(widget.artistInput.id);

              final artistInfo = snapshot.data;
              if (artistCache == null && artistInfo != null) {
                _addArtistToCache(widget.artistInput.id, artistInfo);
              }

              ImageProvider artistImage;
              // Image from the Internet
              if (artistInfo?.images?.first?.text != null) {
                artistImage =
                    CachedNetworkImageProvider(artistInfo.images.first.text);
                // Image from the database
              } else if (artistCache?.imageBinary != null) {
                artistImage = Image.memory(artistCache.imageBinary).image;
                // System designated image
              } else if (widget.artistInput.artistArtPath != null) {
                artistImage =
                    Image.file(File(widget.artistInput.artistArtPath)).image;
                // Default image
              } else {
                artistImage = AssetImage(Constants.defaultArtistPath);
              }
              // Remove HTML tags from bio
              final artistBio =
                  (artistInfo?.bio?.summary ?? artistCache?.bioSummary ?? '')
                      .replaceAll(
                RegExp(r'<a.*<\/a>'),
                '',
              );
              return ListView(
                children: [
                  ArtCoverHeader(
                    height: 220,
                    image: artistImage,
                    content: IntrinsicHeight(
                      child: Row(
                        children: [
                          RoundedImage(
                            image: artistImage,
                            width: 120,
                            height: 160,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.artistInput.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                  ),
                                  Text(
                                    'Albums: ${widget.artistInput.numberOfAlbums}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption
                                          .color,
                                    ),
                                  ),
                                  Text(
                                    'Tracks: ${widget.artistInput.numberOfTracks}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption
                                          .color,
                                    ),
                                  ),
                                  Spacer(),
                                  if (artistInfo?.stats != null) ...[
                                    Text(
                                      'Play count: ${artistInfo.stats.playCount}',
                                    ),
                                    Text(
                                      'Listeners: ${artistInfo.stats.listeners}',
                                    ),
                                  ],
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
                    child: ExpandableText(
                      artistBio,
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 3,
                      linkColor: Colors.blue,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Albums',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<List<AlbumInfo>>(
                      future: audioQuery.getAlbumsFromArtist(
                          artist: widget.artistInput.name),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();
                        final albums = snapshot.data;
                        return buildAlbumList(albums, context);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Songs',
                          style: TextStyle(fontSize: 24),
                        ),
                        Divider()
                      ],
                    ),
                  ),
                  FutureBuilder<List<SongInfo>>(
                    future: audioQuery.getSongsFromArtist(
                        artistId: widget.artistInput.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();
                      final songs =
                          snapshot.data.map(songInfoToMediaItem).toList();
                      return StreamBuilder<MediaItem>(
                          stream: AudioService.currentMediaItemStream,
                          builder: (context, snapshot) {
                            final currentMediaItem = snapshot.data;
                            return Column(
                                children: songs
                                        ?.map((MediaItem song) => SongListTile(
                                              song: song,
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
                                              selected: currentMediaItem?.id ==
                                                  song.id,
                                            ))
                                        ?.toList() ??
                                    []);
                          });
                    },
                  ),
                  SizedBox(height: 60),
                ],
              );
            }));
  }

  Widget buildAlbumList(List<AlbumInfo> albums, BuildContext context) {
    return Container(
      height: 150,
      child: ListView(
          scrollDirection: Axis.horizontal,
          children: albums
                  ?.map((album) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          child: Container(
                            width: 100,
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: RoundedImage(
                                    image: album.albumArt != null
                                        ? Image.file(File(album.albumArt)).image
                                        : AssetImage(
                                            Constants.defaultAlbumPath),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                Text(
                                  album.title,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AlbumScreen(
                                          albumInput: album,
                                        )));
                          },
                        ),
                      ))
                  ?.toList() ??
              []),
    );
  }
}
