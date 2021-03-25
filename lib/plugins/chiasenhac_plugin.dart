import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as Html show parse;
import 'package:http/http.dart' as http;
import 'package:temposcape_player/plugins/player_plugins.dart';

class ChiaSeNhacPlugin extends BasePlayerPlugin {
  ChiaSeNhacPlugin()
      : super(title: 'Chia Sẻ Nhạc', pluginTableInDatabase: 'pluginChiaSeNhac');

  @override
  Widget buildSettingsMenu() {
    // TODO: implement buildSettingsMenu
    throw UnimplementedError();
  }

  @override
  Future<String> getSongUrl(String link) async {
    if (link == null) return null;

    final response = await http.get(link);
    final page = Html.parse(response.body);
    final bestQualityUrl =
        page.querySelectorAll('.download_item[href]').last.attributes['href'];
    return bestQualityUrl;
  }

  @override
  Future<List<OnlineSong>> searchSong(String song, {int page = 1}) async {
    final response = await http.get(
      Uri.https('chiasenhac.vn', 'search/real', {
        'q': song,
        'page_music': page.toString(),
        'type': 'json',
        'view_all': 'true',
      }),
    );

    final List elems = json.decode(response.body)[0]['music']['data'];
    final songs = elems.map<OnlineSong>(
      (e) {
        final songId = e['music_id'].toString();
        return OnlineSong(
            id: songId,
            title: e['music_title'],
            artist: e['music_artist'],
            albumThumbnailUrl: e['music_cover'],
            songUrl: () => getSongUrl(e['music_link']));
      },
    );
    return songs.toList();
  }
}
