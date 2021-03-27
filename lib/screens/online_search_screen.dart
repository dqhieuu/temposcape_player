import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:temposcape_player/plugins/chiasenhac_plugin.dart';
import 'package:temposcape_player/plugins/nhaccuatui_plugin.dart';
import 'package:temposcape_player/plugins/player_plugins.dart';
import 'package:temposcape_player/plugins/soundcloud_plugin.dart';
import 'package:temposcape_player/plugins/zingmp3_plugin.dart';
import 'package:temposcape_player/screens/main_player_screen.dart';
import 'package:temposcape_player/utils/utils.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;

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

  int _page = 1;
  String _searchValue = '';
  bool _hasReachedEnd = false;

  final _plugins = <BasePlayerPlugin>[
    ChiaSeNhacPlugin(),
    ZingMp3Plugin(),
    NhacCuaTuiPlugin(),
    SoundCloudPlugin()
  ];

  _OnlineSearchScreenState() {
    _currentPlugin = _plugins.first;
  }

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
    _page = 1;
    if (_searchValue.trim().isEmpty) {
      print('noop');
      _clearList();
    } else {
      _setList(await _currentPlugin.searchSong(_searchValue));
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
    _scrollController = new ScrollController();
    _scrollController.addListener(() async {
      if (_hasReachedEnd) return;

      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      const delta = 20.0;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Online song plugins'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
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
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: _list
                      ?.map((OnlineSong song) => OnlineSongListTile(
                            song: song,
                            onTap: () async {
                              final songUrl = await song.songUrl();
                              if (songUrl == null || songUrl.isEmpty) return;
                              await AudioService.updateQueue(<MediaItem>[
                                MediaItem(
                                  id: song.id,
                                  artist: song.artist,
                                  title: song.title,
                                  album: '',
                                  extras: SongExtraInfo(
                                    isOnline: true,
                                    uri: songUrl,
                                  ).toMap(),
                                  artUri: song.albumArtUrl ??
                                      song.albumThumbnailUrl,
                                ),
                              ]);
                              AudioService.play();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MainPlayerScreen()));
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
