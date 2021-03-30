import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:temposcape_player/screens/home_screen_tabs/album_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/artist_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/favorite_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/genre_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/playlist_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/song_tab.dart';
import 'package:temposcape_player/screens/online_search_screen.dart';
import 'package:temposcape_player/screens/song_queue_screen.dart';
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

  _HomeScreenState() {
    audioQuery.getPlaylists().then((playlists) {
      if (playlists
          .where((playlist) => playlist.name == Constants.favoritesPlaylist)
          .isEmpty) {
        FlutterAudioQuery.createPlaylist(
            playlistName: Constants.favoritesPlaylist);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: myTabs.length);
    _searchBar = new SearchBar(
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
          case 4:
            searchFavorites(value);
            break;
          case 5:
            searchGenres(value);
            break;
        }
      },
      onClosed: _clearSearchResult,
      onCleared: _clearSearchResult,
    );
    _tabController.addListener(() {
      // Clear search result when switching tab
      _clearSearchResult();
    });
  }

  void _clearSearchResult() {
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

  void searchFavorites(String value) async {
    if (value == null) {
      setState(() {
        searchResult = null;
      });
      return;
    }

    final favoritePlaylist =
        (await audioQuery.searchPlaylists(query: Constants.favoritesPlaylist))
            ?.first;
    if (favoritePlaylist != null) {
      searchResult =
          (await audioQuery.getSongsFromPlaylist(playlist: favoritePlaylist))
              ?.where((song) => song.title?.toLowerCase()?.contains(value))
              ?.toList();
    }
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
      actions: [
        _searchBar.getSearchAction(context),
        IconButton(icon: Icon(Icons.more_vert)),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        unselectedLabelColor: Colors.white38,
        tabs: myTabs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OnlineSearchScreen()));
              },
            ),
            ListTile(
              title: Text('Queue'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SongQueueScreen()));
              },
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                // TODO: implement this
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              SongTab(searchResult: searchResult),
              AlbumTab(searchResult: searchResult),
              ArtistTab(searchResult: searchResult),
              PlaylistTab(searchResult: searchResult),
              FavoriteTab(searchResult: searchResult),
              GenreTab(searchResult: searchResult)
            ]),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainPlayerScreen()),
        );
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(color: Theme.of(context).bottomAppBarColor),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<MediaItem>(
              stream: AudioService.currentMediaItemStream,
              builder: (context, snapshot) {
                final song = snapshot.data;
                return Row(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: RoundedImage(
                          image: (song?.artUri != null
                              ? ((song?.extras ?? {})['isOnline'] ?? false
                                  ? CachedNetworkImageProvider(song.artUri)
                                  : Image.file(
                                          File(Uri.parse(song.artUri).path))
                                      .image)
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
                            song?.artist ?? 'Source not found',
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
      ),
    );
  }
}
