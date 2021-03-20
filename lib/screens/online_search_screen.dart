import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/plugins/player_plugins.dart';
import 'package:temposcape_player/screens/main_player_screen.dart';
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
  SearchBar _searchBar;

  List<OnlineSong> _list = [];

  Timer _debounce;

  var zing = ZingMp3Plugin();

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
        title: Text('Zingmp3 test'),
        flexibleSpace: FlexibleSpaceBar(),
        actions: [_searchBar.getSearchAction(context)]);
  }

  _OnlineSearchScreenState() {
    _searchBar = new SearchBar(
        inBar: false,
        setState: setState,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce.cancel();
          _debounce = Timer(const Duration(milliseconds: 200), () async {
            updateList(await zing.searchSong(value));
          });
        },
        onSubmitted: (String value) async {
          var zing = ZingMp3Plugin();
          updateList(await zing.searchSong(value));
        },
        buildDefaultAppBar: buildAppBar);
  }

  void updateList(List<OnlineSong> newList) {
    setState(() {
      _list = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayer>(
      builder: (_, player, __) => Scaffold(
        appBar: _searchBar.build(context),
        body: ListView(
          children: _list
                  ?.map((OnlineSong song) => OnlineSongListTile(
                        song: song,
                        onTap: () async {
                          final songUrl = await song.songUrl();
                          await player.setAudioSource(ProgressiveAudioSource(
                              Uri.parse(songUrl),
                              tag: SongInfo(
                                  artist: song.artist,
                                  title: song.title,
                                  isPodcast: true,
                                  filePath: songUrl,
                                  albumArtwork: song.albumArtUrl)));
                          player.play();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MainPlayerScreen()));
                        },
                      ))
                  ?.toList() ??
              [],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
