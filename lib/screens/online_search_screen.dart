import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:temposcape_player/plugins/player_plugins.dart';
import 'package:temposcape_player/widgets/widgets.dart';

import '../constants/constants.dart' as Constants;

class OnlineSearchScreen extends StatefulWidget {
  @override
  _OnlineSearchScreenState createState() => _OnlineSearchScreenState();
}

class OnlineSongListTile extends StatelessWidget {
  final NetworkSong song;
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
  SearchBar searchBar;

  List<NetworkSong> list = [];

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
        title: new Text('Zingmp3test'),
        actions: [searchBar.getSearchAction(context)]);
  }

  _OnlineSearchScreenState() {
    searchBar = new SearchBar(
        inBar: false,
        setState: setState,
        onChanged: (value) {
          print(value);
        },
        onSubmitted: (String value) async {
          var zing = ZingMp3Plugin();
          updateList(await zing.searchSong(value));
        },
        buildDefaultAppBar: buildAppBar);
  }

  void updateList(List<NetworkSong> newList) {
    setState(() {
      list = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: searchBar.build(context),
      body: ListView(
        children: list
                ?.map((NetworkSong song) => OnlineSongListTile(song: song))
                ?.toList() ??
            [],
      ),
    );
  }
}
