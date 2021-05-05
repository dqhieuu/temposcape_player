import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/plugins/plugins.dart';
import 'package:temposcape_player/utils/hashing.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;
import 'main_player_screen.dart';

class OnlineSearchScreen extends StatefulWidget {
  @override
  _OnlineSearchScreenState createState() => _OnlineSearchScreenState();
}

class OnlineSongListTile extends StatelessWidget {
  final OnlineSong song;
  final GestureTapCallback onTap;
  final bool selected;

  const OnlineSongListTile({
    Key key,
    this.song,
    this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: RoundedImage(
        image: song?.albumThumbnailUrl != null
            ? CachedNetworkImageProvider(song.albumThumbnailUrl)
            : AssetImage(Constants.defaultImagePath),
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(10),
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
    );
  }
}

class _OnlineSearchScreenState extends State<OnlineSearchScreen> {
  List<OnlineSong> _list = [];
  Timer _debounce;
  ScrollController _scrollController;
  BasePlayerPlugin _currentPlugin;

  int _lastSearchTimestamp;
  int _page = 1;
  String _searchValue = '';
  bool _hasReachedEnd = false;
  bool _havingBlockingTask = false;

  List<BasePlayerPlugin> _plugins;

  void _setList(List<OnlineSong> newList) {
    setState(() {
      _list = newList;
    });
  }

  void _addToList(List<OnlineSong> newList) {
    setState(() {
      _list.addAll(newList);
    });
  }

  void _clearList() {
    setState(() {
      _list.clear();
    });
  }

  Future<void> _setListAccordingToText() async {
    final thisSearchTimestamp = DateTime.now().millisecondsSinceEpoch;
    _lastSearchTimestamp = thisSearchTimestamp;
    _page = 1;
    // Clear list if input is empty and plugin doesn't have a default list
    if (_searchValue.trim().isEmpty &&
        !(_currentPlugin != null && _currentPlugin.allowEmptySearch)) {
      _clearList();
    } else {
      // This takes a long time to resolve, that's why we need to check if this is the latest search
      final songData = await _currentPlugin.searchSong(_searchValue);
      if (_lastSearchTimestamp != null &&
          _lastSearchTimestamp > thisSearchTimestamp) {
        return;
      }
      _setList(songData);
      // Scroll to top on new search
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _plugins = context
        .read<List<BasePlayerPlugin>>()
        .where((plugin) =>
            plugin.getValueFromDatabase<bool>('enabled', defaultValue: true))
        .toList();
    _currentPlugin = _plugins.isNotEmpty ? _plugins.first : null;
    // Show default plugin's list
    _setListAccordingToText();

    _scrollController = new ScrollController();
    _scrollController.addListener(() async {
      if (_hasReachedEnd) return;

      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      const delta = 50.0;

      if (maxScroll - currentScroll <= delta) {
        _page++;
        final newPage = await _currentPlugin.searchSong(
          _searchValue,
          page: _page,
        );

        if (newPage == null || newPage.isEmpty) {
          _hasReachedEnd = true;
          return;
        }
        _addToList(newPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: isLightMode ? Color(0xFFEFEFEF) : null,
            iconTheme: isLightMode ? IconThemeData(color: Colors.black) : null,
            pinned: true,
            snap: true,
            floating: true,
            expandedHeight: 155.0,
            title: Text(
              'Online song plugins',
              style: isLightMode ? TextStyle(color: Colors.black) : null,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    Spacer(),
                    DropdownButton(
                      items: _plugins.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e.title));
                      }).toList(),
                      isExpanded: true,
                      onChanged: (BasePlayerPlugin selectedPlugin) {
                        setState(() {
                          _currentPlugin = selectedPlugin;
                          _setListAccordingToText();
                        });
                      },
                      value: _currentPlugin,
                    ),
                    TextField(
                      onChanged: (value) {
                        _searchValue = value;
                        if (_debounce?.isActive ?? false) _debounce.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300),
                            _setListAccordingToText);
                      },
                      decoration: InputDecoration(
                        hintText: "Search online...",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              _list
                      ?.map((OnlineSong song) => OnlineSongListTile(
                            song: song,
                            onTap: () async {
                              if (_havingBlockingTask) return;
                              _havingBlockingTask = true;
                              // Getting the song url may take long, so we need a flag to check if we're already requesting something.
                              final songUrl = await song.songUrl();
                              // Disable the blocking flag
                              _havingBlockingTask = false;
                              if (songUrl == null || songUrl.isEmpty) return;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MainPlayerScreen()));
                              await AudioService.updateQueue(<MediaItem>[
                                MediaItem(
                                  id: song.id,
                                  artist: song.artist,
                                  title: song.title,
                                  album: '',
                                  extras: SongExtraInfo(
                                    isOnline: true,
                                    uri: songUrl,
                                  ).toMap()
                                    ..putIfAbsent(
                                        // add checksum value
                                        'checkSum',
                                        () => hashOnlineSong(
                                              id: song.id,
                                              source: _currentPlugin.title,
                                            )),
                                  artUri: song.albumArtUrl ??
                                      song.albumThumbnailUrl,
                                ),
                              ]);
                              AudioService.play();
                            },
                          ))
                      ?.toList() ??
                  [],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
