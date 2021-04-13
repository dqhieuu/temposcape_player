import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:temposcape_player/screens/home_screen_tabs/album_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/artist_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/favorite_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/playlist_tab.dart';
import 'package:temposcape_player/screens/home_screen_tabs/song_tab.dart';
import 'package:temposcape_player/screens/online_search_screen.dart';
import 'package:temposcape_player/screens/settings_screen.dart';
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
  final _myTabs = <Tab>[
    const Tab(text: 'Songs'),
    const Tab(text: 'Albums'),
    const Tab(text: 'Artists'),
    const Tab(text: 'Playlists'),
    const Tab(text: 'Favorites'),
    // const Tab(text: 'Genres'),
  ];
  TabController _tabController;
  SearchBar _searchBar;
  PreferredSizeWidget _multiSelectBar;
  bool _tabSwipeable = true;
  final FlutterAudioQuery _audioQuery = FlutterAudioQuery();

  bool _reverseOrder = false;
  int _currentTabIndex = 0;
  List<dynamic> _searchResult;

  _HomeScreenState() {
    _audioQuery.getPlaylists().then((playlists) {
      if (playlists
          .where(
              (playlist) => playlist.name == Constants.favoritesPlaylistHiveBox)
          .isEmpty) {
        FlutterAudioQuery.createPlaylist(
            playlistName: Constants.favoritesPlaylistHiveBox);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _myTabs.length);
    _searchBar = new SearchBar(
      setState: setState,
      buildDefaultAppBar: buildAppBar,
      onChanged: (String value) async {
        switch (_currentTabIndex) {
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
      if (_tabController.index != null) {
        _currentTabIndex = _tabController.index;
      }
      // Clear search result when switching tab
      _clearSearchResult();
    });
  }

  void _clearSearchResult() {
    _searchResult = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void searchSongs(String value) async {
    _searchResult =
        value != null ? await _audioQuery.searchSongs(query: value) : null;
    setState(() {});
  }

  void searchAlbums(String value) async {
    _searchResult =
        value != null ? await _audioQuery.searchAlbums(query: value) : null;
    setState(() {});
  }

  void searchArtists(String value) async {
    _searchResult =
        value != null ? await _audioQuery.searchArtists(query: value) : null;
    setState(() {});
  }

  void searchPlaylists(String value) async {
    _searchResult =
        value != null ? await _audioQuery.searchPlaylists(query: value) : null;
    setState(() {});
  }

  void searchFavorites(String value) async {
    if (value == null) {
      setState(() {
        _searchResult = null;
      });
      return;
    }

    final favoritePlaylist = (await _audioQuery.searchPlaylists(
            query: Constants.favoritesPlaylistHiveBox))
        ?.first;
    if (favoritePlaylist != null) {
      _searchResult =
          (await _audioQuery.getSongsFromPlaylist(playlist: favoritePlaylist))
              ?.where((song) => song.title?.toLowerCase()?.contains(value))
              ?.toList();
    }
    setState(() {});
  }

  void searchGenres(String value) async {
    _searchResult =
        value != null ? await _audioQuery.searchGenres(query: value) : null;
    setState(() {});
  }

  var options = ['Ascending', 'Descending'];

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(Constants.appName),
      actions: <Widget>[
        _searchBar.getSearchAction(context),
        PopupMenuButton<String>(
          onSelected: (str) {
            switch (str) {
              case 'onlsearch':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OnlineSearchScreen()));
                break;
              case 'settings':
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
                break;
              case 'order':
                setState(() {
                  _reverseOrder = !_reverseOrder;
                });
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // PopupMenuItem(
              //   value: 'sort',
              //   child: const Text('Sort by...'),
              // ),
              // PopupMenuItem(
              //   value: 'order',
              //   child: Row(
              //     children: [
              //       Text('Order: '),
              //       !_reverseOrder
              //           ? Row(
              //               children: [
              //                 Text('Ascending '),
              //                 Icon(
              //                   Icons.arrow_upward_rounded,
              //                   color:
              //                       Theme.of(context).textTheme.bodyText1.color,
              //                 ),
              //               ],
              //             )
              //           : Row(
              //               children: [
              //                 Text('Descending '),
              //                 Icon(
              //                   Icons.arrow_downward_rounded,
              //                   color:
              //                       Theme.of(context).textTheme.bodyText1.color,
              //                 ),
              //               ],
              //             )
              //     ],
              //   ),
              // ),
              PopupMenuItem(
                value: 'onlsearch',
                child: const Text('Online search'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: const Text('Settings'),
              ),
            ];
          },
        )
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _myTabs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _multiSelectBar ?? _searchBar.build(context),
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logo_line.svg',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  Text(
                    Constants.appName,
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_rounded),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search_rounded),
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
              leading: Icon(Icons.queue_music_rounded),
              title: Text('Queue'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SongQueueScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_rounded),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
                controller: _tabController,
                physics: _tabSwipeable ? null : NeverScrollableScrollPhysics(),
                children: [
                  SongTab(
                    searchResult: _searchResult,
                    reverseOrder: _reverseOrder,
                    tabAppBarCallback: (tabAppBar) {
                      setState(() {
                        _multiSelectBar = tabAppBar;
                        _tabSwipeable = (_multiSelectBar == null);
                      });
                    },
                  ),
                  AlbumTab(searchResult: _searchResult),
                  ArtistTab(searchResult: _searchResult),
                  PlaylistTab(
                    searchResult: _searchResult,
                    reverseOrder: _reverseOrder,
                    tabAppBarCallback: (tabAppBar) {
                      setState(() {
                        _multiSelectBar = tabAppBar;
                        _tabSwipeable = (_multiSelectBar == null);
                      });
                    },
                  ),
                  FavoriteTab(
                    searchResult: _searchResult,
                    reverseOrder: _reverseOrder,
                    tabAppBarCallback: (tabAppBar) {
                      setState(() {
                        _multiSelectBar = tabAppBar;
                        _tabSwipeable = (_multiSelectBar == null);
                      });
                    },
                  ),
                  // GenreTab(searchResult: _searchResult)
                ]),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}

class WidgetWithRightArrow extends StatelessWidget {
  final Widget child;

  const WidgetWithRightArrow({
    this.child,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        child,
        Spacer(),
        Icon(Icons.arrow_right, size: 30.0),
      ],
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
        height: 60,
        decoration: BoxDecoration(color: Theme.of(context).bottomAppBarColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: StreamBuilder<MediaItem>(
              stream: AudioService.currentMediaItemStream,
              builder: (context, snapshot) {
                final song = snapshot.data;
                return Row(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: RoundedImage(
                        image: song?.artUri != null
                            ? (song?.extras ?? {})['isOnline'] ?? false
                                ? CachedNetworkImageProvider(song.artUri)
                                : Image.file(File(Uri.parse(song.artUri).path))
                                    .image
                            : AssetImage(Constants.defaultImagePath),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    VerticalDivider(
                      thickness: 2,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MyMarquee(
                            song?.title ?? 'No song selected',
                            height: 28,
                            fontSize: 18,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          MyMarquee(
                            song?.artist ?? 'Source not found',
                            height: 22,
                            fontSize: 14,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.caption.color,
                            ),
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
