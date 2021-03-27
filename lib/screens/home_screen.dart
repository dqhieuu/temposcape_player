import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/screens/online_search_screen.dart';
import 'package:temposcape_player/screens/song_queue_screen.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

/// A home page where songs are displayed.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final myTabs = <Tab>[
    const Tab(text: 'Songs'),
    const Tab(text: 'Albums'),
    const Tab(text: 'Artists'),
    const Tab(text: 'Playlists'),
    const Tab(text: 'Favorites'),
    const Tab(text: 'Genres'),
  ];
  TabController _tabController;
  SearchBar _searchBar;
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  List<dynamic> searchResult;

  @override
  void initState() {
    super.initState();
    Hive.box<String>(Constants.cachedArtists).clear();
    _tabController = TabController(vsync: this, length: myTabs.length);
    _searchBar = new SearchBar(
      // TODO: fix bugs, this has bugs, don't know why
      inBar: true,
      setState: setState,
      buildDefaultAppBar: buildAppBar,
      onChanged: (String value) async {
        switch (_tabController.index) {
          case 0:
            searchSongs(value);
            break;
          case 1:
            searchAlbums(value);
            break;
          case 2:
            searchArtists(value);
            break;
          case 3:
            searchPlaylists(value);
            break;
          case 5:
            searchGenres(value);
            break;
        }
      },
      onClosed: () {
        searchResult = null;
      },
    );
    _tabController.addListener(() {
      clearSearchResult();
    });
  }

  void clearSearchResult() {
    searchResult = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void searchSongs(String value) async {
    searchResult =
        value != null ? await audioQuery.searchSongs(query: value) : null;
    setState(() {});
  }

  void searchAlbums(String value) async {
    searchResult =
        value != null ? await audioQuery.searchAlbums(query: value) : null;
    setState(() {});
  }

  void searchArtists(String value) async {
    searchResult =
        value != null ? await audioQuery.searchArtists(query: value) : null;
    setState(() {});
  }

  void searchPlaylists(String value) async {
    searchResult =
        value != null ? await audioQuery.searchPlaylists(query: value) : null;
    setState(() {});
  }

  void searchGenres(String value) async {
    searchResult =
        value != null ? await audioQuery.searchGenres(query: value) : null;
    setState(() {});
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(Constants.appName),
      actions: [_searchBar.getSearchAction(context)],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        unselectedLabelColor: Colors.white38,
        tabs: myTabs,
      ),
    );
  }

  void showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final myController = TextEditingController();
        return AlertDialog(
          title: Text('Add playlist'),
          content: TextField(
            controller: myController,
            decoration: InputDecoration(
              labelText: "Title",
            ),
          ),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FlatButton(
              onPressed: () async {
                await FlutterAudioQuery.createPlaylist(
                    playlistName: myController.text);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();
    return Scaffold(
      appBar: _searchBar.build(context),
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(Constants.appName),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Online search'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OnlineSearchScreen()));
              },
            ),
            ListTile(
              title: Text('Queue'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SongQueueScreen()));
              },
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                // TODO: implement this
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              FutureBuilder<List<SongInfo>>(
                  future: audioQuery.getSongs(),
                  builder: (context, snapshot) {
                    final allSongsWithoutSystemMusic = snapshot.data
                        ?.where((song) =>
                            !song.filePath.contains(r'/Android/media/'))
                        ?.toList();
                    final songs = searchResult as List<SongInfo> ??
                        allSongsWithoutSystemMusic;
                    // return StreamBuilder<SequenceState>(
                    //     stream: player.sequenceStateStream,
                    //     builder: (context, snapshot) {
                    //       final audioSource = songs
                    //           ?.map((e) =>
                    //               AudioSource.uri(Uri.file(e.filePath), tag: e))
                    //           ?.toList();
                    //       return ListView(
                    //         children: songs
                    //                 ?.toList()
                    //                 ?.map((SongInfo song) => SongListTile(
                    //                       song: song,
                    //                       onTap: () async {
                    //                         // TODO: optimize this
                    //                         // await player.setAudioSource(
                    //                         //     ProgressiveAudioSource(
                    //                         //         Uri.file(song.filePath),
                    //                         //         tag: song));
                    //                         // player.play();
                    //                         await player.setAudioSource(
                    //                             ConcatenatingAudioSource(
                    //                                 children: audioSource));
                    //                         await player.seek(Duration.zero,
                    //                             index: songs.indexOf(song));
                    //                         player.play();
                    //                         Navigator.push(
                    //                           context,
                    //                           MaterialPageRoute(
                    //                               builder: (context) =>
                    //                                   MainPlayerScreen()),
                    //                         );
                    //                       },
                    //                       selected: (snapshot
                    //                                   .data?.currentSource?.tag)
                    //                               ?.filePath ==
                    //                           song.filePath,
                    //                     ))
                    //                 ?.toList() ??
                    //             [],
                    //       );
                    //     });
                    return ListView(
                      children: songs
                              ?.toList()
                              ?.map((SongInfo song) => SongListTile(
                                    song: songInfoToMediaItem(song),
                                    onTap: () async {
                                      await AudioService.updateQueue(songs
                                          .map(songInfoToMediaItem)
                                          .toList());
                                      await AudioService.skipToQueueItem(
                                          song.id);
                                      AudioService.play();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MainPlayerScreen()),
                                      );
                                    },
                                    // selected:
                                    //     (snapshot.data?.currentSource?.tag)
                                    //             ?.filePath ==
                                    //         song.filePath,
                                  ))
                              ?.toList() ??
                          [],
                    );
                  }),
              FutureBuilder<List<AlbumInfo>>(
                  future: audioQuery.getAlbums(),
                  builder: (context, snapshot) {
                    final albums =
                        searchResult as List<AlbumInfo> ?? snapshot.data;
                    return OrientationBuilder(builder: (context, orientation) {
                      return GridView.count(
                        crossAxisCount: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? 3
                            : 5,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 0.75,
                        children: albums?.map((AlbumInfo album) {
                              return MyGridTile(
                                child: Column(
                                  children: [
                                    album?.albumArt != null
                                        ? Image.file(File(album.albumArt))
                                        : Image(
                                            image: AssetImage(
                                                Constants.defaultImagePath),
                                          ),
                                    Text(
                                      album.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    )
                                  ],
                                ),
                              );
                            })?.toList() ??
                            [],
                      );
                    });
                  }),
              FutureBuilder<List<ArtistInfo>>(
                  future: audioQuery.getArtists(),
                  builder: (context, snapshot) {
                    final artists =
                        searchResult as List<ArtistInfo> ?? snapshot.data;
                    Hive.box<String>(Constants.cachedArtists).clear();
                    return GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.55,
                      children: artists?.map((ArtistInfo artist) {
                            // return FutureBuilder<lastFm.Artist>(
                            //   future: scrobblenaut
                            //       .Scrobblenaut.instance.artist
                            //       .getInfo(artist: artist.name),
                            //   builder: (context, snapshot) {
                            //     String dbArtistArtUrl = Hive.box<String>(
                            //             Constants.cachedArtists)
                            //         .get(base64.encode(
                            //             utf8.encode(artist.name)));
                            //     if (dbArtistArtUrl == null) {
                            //       print('this');
                            //       final lastFmArtistArtUrl =
                            //           snapshot.data?.images?.last?.text;
                            //       dbArtistArtUrl =
                            //           lastFmArtistArtUrl ?? '';
                            //       print(dbArtistArtUrl);
                            //       Hive.box<String>(
                            //               Constants.cachedArtists)
                            //           .put(
                            //               base64.encode(
                            //                   utf8.encode(artist.name)),
                            //               dbArtistArtUrl);
                            //     }
                            return MyGridTile(
                              child: Column(children: [
                                AspectRatio(
                                  aspectRatio: 0.7,
                                  child:
                                      // dbArtistArtUrl.isNotEmpty
                                      //     ? CachedNetworkImage(
                                      //         imageUrl: dbArtistArtUrl,
                                      //         placeholder: (context,
                                      //                 url) =>
                                      //             CircularProgressIndicator(),
                                      //         errorWidget:
                                      //             (context, url, error) =>
                                      //                 Icon(Icons.error),
                                      //         fit: BoxFit.cover,
                                      //       )
                                      //     :
                                      artist?.artistArtPath != null
                                          ? Image.file(
                                              File(artist.artistArtPath),
                                              fit: BoxFit.cover,
                                            )
                                          : Image(
                                              image: AssetImage(
                                                  Constants.defaultImagePath),
                                              fit: BoxFit.cover,
                                            ),
                                ),
                                Text(
                                  artist.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ]),
                            );
                            // },
                            // );
                          })?.toList() ??
                          [],
                    );
                  }),
              // TODO: implement this
              FutureBuilder<List<PlaylistInfo>>(
                  future: audioQuery.getPlaylists(),
                  builder: (context, snapshot) {
                    final playlists = snapshot.data?.toList();
                    if (playlists != null && playlists.isNotEmpty) {
                      return Scaffold(
                        floatingActionButton: FloatingActionButton(
                          child: Icon(Icons.add),
                          onPressed: showAddPlaylistDialog,
                        ),
                        body: ListView(
                          children: playlists
                              .toList()
                              .map((PlaylistInfo playlist) => ListTile(
                                    leading: RoundedImage(
                                      image: AssetImage(
                                          Constants.defaultImagePath),
                                      width: 30,
                                      height: 30,
                                    ),
                                    title: Text(
                                      playlist.name,
                                      maxLines: 1,
                                    ),
                                  ))
                              .toList(),
                        ),
                      );
                    }
                    return Center(
                      child: GestureDetector(
                        onTap: showAddPlaylistDialog,
                        child: Column(
                          children: [
                            IconButton(icon: Icon(Icons.add), onPressed: null),
                            Text('Add a playlist here'),
                          ],
                        ),
                      ),
                    );
                  }),
              // TODO: implement this
              Icon(Icons.directions_bike),
              FutureBuilder<List<GenreInfo>>(
                  future: audioQuery.getGenres(),
                  builder: (context, snapshot) {
                    final genres =
                        searchResult as List<GenreInfo> ?? snapshot.data;
                    final random = Random();
                    return GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 1.3,
                      children: genres?.map((GenreInfo genre) {
                            var genreImagePath =
                                Hive.box<String>(Constants.cachedGenres).get(
                              base64.encode(utf8.encode(genre.name)),
                            );
                            if (genreImagePath == null) {
                              genreImagePath = Constants.genreImagePaths[random
                                  .nextInt(Constants.genreImagePaths.length)];
                              Hive.box<String>(Constants.cachedGenres).put(
                                  base64.encode(utf8.encode(genre.name)),
                                  genreImagePath);
                            }
                            return MyGridTile(
                              child: Column(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.7,
                                    child: Image(
                                      image: AssetImage(genreImagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Text(
                                    genre.name,
                                    maxLines: 1,
                                  )
                                ],
                              ),
                            );
                          })?.toList() ??
                          [],
                    );
                  }),
            ]),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainPlayerScreen()),
              );
            },
            child: MiniPlayer(player: player),
          ),
        ],
      ),
    );
  }
}

class MyGridTile extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;
  const MyGridTile({
    this.child,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GridTile(child: child),
      Positioned.fill(
          child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
        ),
      )),
    ]);
  }
}

class MiniPlayer extends StatelessWidget {
  final AudioPlayer player;
  const MiniPlayer({
    this.player,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Theme.of(context).bottomAppBarColor),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        // child: StreamBuilder<PlayerState>(
        //     stream: player.playerStateStream,
        //     builder: (context, snapshot) {
        //       return StreamBuilder<SequenceState>(
        //           stream: player.sequenceStateStream,
        //           builder: (context, snapshot) {
        //             final song = snapshot.data?.currentSource?.tag;
        //             return Row(
        //               children: [
        //                 AspectRatio(
        //                   aspectRatio: 1,
        //                   child: RoundedImage(
        //                     image: song?.isPodcast ?? false
        //                         ? (song?.albumArtwork != null
        //                             ? Image.network(song?.albumArtwork).image
        //                             : AssetImage(Constants.defaultImagePath))
        //                         : (song?.albumArtwork != null
        //                             ? Image.file(File(song?.albumArtwork)).image
        //                             : AssetImage(Constants.defaultImagePath)),
        //                   ),
        //                 ),
        //                 VerticalDivider(
        //                   thickness: 2,
        //                 ),
        //                 Expanded(
        //                   child: Column(
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //                     children: [
        //                       Text(
        //                         song?.title ?? 'No song selected',
        //                         style: TextStyle(
        //                           fontSize: 20,
        //                         ),
        //                         overflow: TextOverflow.ellipsis,
        //                       ),
        //                       Text(
        //                         song?.artist ?? 'Various artists',
        //                         style: TextStyle(
        //                           fontSize: 16,
        //                           color:
        //                               Theme.of(context).textTheme.caption.color,
        //                         ),
        //                         overflow: TextOverflow.ellipsis,
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 VerticalDivider(
        //                   thickness: 2,
        //                 ),
        //                 StreamBuilder<PlayerState>(
        //                     stream: player.playerStateStream,
        //                     builder: (context, snapshot) {
        //                       if (snapshot.data?.playing ?? false) {
        //                         return IconButton(
        //                           onPressed: () {
        //                             player.pause();
        //                           },
        //                           icon: Icon(FontAwesomeIcons.pause),
        //                         );
        //                       }
        //                       return IconButton(
        //                         onPressed: () {
        //                           player.play();
        //                         },
        //                         icon: Icon(FontAwesomeIcons.play),
        //                       );
        //                     }),
        //               ],
        //             );
        //           });
        //     }),
        child: StreamBuilder<MediaItem>(
            stream: AudioService.currentMediaItemStream,
            builder: (context, snapshot) {
              final song = snapshot.data;
              return Row(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: RoundedImage(
                        // image: song?.extras['isPodcast'] ?? false
                        //     ? (song?.artUri != null
                        //         ? Image.network(song?.artUri).image
                        //         : AssetImage(Constants.defaultImagePath))
                        //     : (song?.artUri != null
                        //         ? Image.file(File(song?.artUri)).image
                        //         : AssetImage(Constants.defaultImagePath)),
                        image: (song?.artUri != null
                            ? ((song?.extras ?? {})['isOnline'] ?? false
                                ? Image.network(song.artUri).image
                                : Image.file(File(song.artUri)).image)
                            : AssetImage(Constants.defaultImagePath))),
                  ),
                  VerticalDivider(
                    thickness: 2,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          song?.title ?? 'No song selected',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song?.artist ?? 'Various artists',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.caption.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    thickness: 2,
                  ),
                  StreamBuilder<PlaybackState>(
                      stream: AudioService.playbackStateStream,
                      builder: (context, snapshot) {
                        if (snapshot.data?.playing ?? false) {
                          return IconButton(
                            onPressed: () {
                              AudioService.pause();
                            },
                            icon: Icon(FontAwesomeIcons.pause),
                          );
                        }
                        return IconButton(
                          onPressed: () {
                            AudioService.play();
                          },
                          icon: Icon(FontAwesomeIcons.play),
                        );
                      }),
                ],
              );
            }),
      ),
    );
  }
}

class SongListTile extends StatelessWidget {
  final MediaItem song;
  final GestureTapCallback onTap;
  final bool selected;
  final bool draggable;

  const SongListTile({
    Key key,
    this.song,
    this.onTap,
    this.selected = false,
    this.draggable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(song.id),
      leading: RoundedImage(
        image: song.artUri != null
            ? Image.file(File(song.artUri)).image
            : AssetImage(Constants.defaultImagePath),
        width: 50,
        height: 50,
      ),
      onTap: onTap,
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
      selected: selected,
      trailing: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getFormattedDuration(
                song.duration,
                timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
              ),
            ),
            if (draggable)
              Container(
                child: Icon(
                  Icons.drag_handle,
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
