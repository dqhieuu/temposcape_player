import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as Html show parse;
import 'package:http/http.dart' as http;
import 'package:temposcape_player/plugins/player_plugins.dart';

class NhacCuaTuiPlugin extends BasePlayerPlugin {
  NhacCuaTuiPlugin()
      : super(title: 'NhacCuaTui', pluginTableInDatabase: 'pluginNhacCuaTui');

  @override
  Widget buildSettingsMenu() {
    // TODO: implement buildSettingsMenu
    throw UnimplementedError();
  }

  @override
  Future<String> getSongUrl(String songId) async {
    final response = await http.get(
        'https://www.nhaccuatui.com/download/song/${songId}_128',
        headers: {
          HttpHeaders.refererHeader: 'https://www.nhaccuatui.com/',
        });
    final url = json.decode(response.body)['data']['stream_url'];
    return url;
  }

  @override
  Future<List<OnlineSong>> searchSong(String song, {int page = 1}) async {
    final response = await http.get(
        Uri.http('m.nhaccuatui.com', 'ajax/search-all', {
          'page': page.toString(),
          'q': song,
          'b': 'title',
          's__type': 'bai-hat',
          'sort': '0'
        }),
        headers: {
          HttpHeaders.refererHeader: 'https://www.nhaccuatui.com/',
        });

    final site = Html.parse(json.decode(response.body)['data']);
    final elems = site.getElementsByClassName('song_item_single');
    final songs = elems.map<OnlineSong>(
      (e) {
        final songId = e.querySelector('.title_song > a').attributes['key'];
        return OnlineSong(
            id: songId,
            title: e.querySelector('.title_song > a').text,
            artist: e.querySelector('.singer_song > a').text,
            albumThumbnailUrl:
                e.querySelector('.item_thumb > a > img').attributes['data-src'],
            songUrl: () => getSongUrl(songId));
      },
    );
    return songs.toList();
  }
}
