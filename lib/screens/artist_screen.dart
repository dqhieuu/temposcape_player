import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
              if (artistInfo?.images?.first?.text != null) {
                artistImage =
                    CachedNetworkImageProvider(artistInfo.images.first.text);
              } else if (artistCache?.imageBinary != null) {
                artistImage = Image.memory(artistCache.imageBinary).image;
              } else if (widget.artistInput.artistArtPath != null) {
                artistImage =
                    Image.file(File(widget.artistInput.artistArtPath)).image;
              } else {
                artistImage = AssetImage(Constants.defaultImagePath);
              }

              final artistBio = (artistInfo?.bio?.summary ??
                      artistCache?.bioSummary ??
                      'No biography')
                  .replaceAll(
                RegExp(r'<a.*<\/a>'),
                '',
              );
              return ListView(
                children: [
                  ArtCoverHeader(
                    height: 220,
                    image: artistImage,
                    content: Row(
                      children: [
                        Image(
                          image: artistImage,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 160,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.artistInput.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Albums: ${widget.artistInput.numberOfAlbums}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Tracks: ${widget.artistInput.numberOfTracks}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(artistBio),
                      ],
                    ),
                  ),
                  Text('Albums'),
                  FutureBuilder<List<AlbumInfo>>(
                    future: audioQuery.getAlbumsFromArtist(
                        artist: widget.artistInput.name),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();
                      final albums = snapshot.data;
                      return Container(
                        height: 150,
                        child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: albums
                                    ?.map((album) => MyGridTile(
                                          child: Container(
                                            width: 100,
                                            child: Column(
                                              children: [
                                                Image(
                                                  image: album.albumArt != null
                                                      ? Image.file(File(
                                                              album.albumArt))
                                                          .image
                                                      : AssetImage(Constants
                                                          .defaultAlbumPath),
                                                ),
                                                Text(
                                                  album.title,
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                )
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AlbumScreen(
                                                          albumInput: album,
                                                        )));
                                          },
                                        ))
                                    ?.toList() ??
                                []),
                      );
                    },
                  ),
                  Text('Tracks'),
                  FutureBuilder<List<SongInfo>>(
                    future: audioQuery.getSongsFromArtist(
                        artistId: widget.artistInput.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();
                      final songs =
                          snapshot.data.map(songInfoToMediaItem).toList();
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
                                          await AudioService.skipToQueueItem(
                                              song.id);
                                          AudioService.play();
                                        },
                                        // selected:
                                        //     (snapshot.data?.currentSource?.tag)
                                        //             ?.filePath ==
                                        //         song.filePath,
                                      ))
                                  ?.toList() ??
                              []);
                    },
                  ),
                ],
              );
            }));
  }
}
