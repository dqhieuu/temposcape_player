import 'package:flutter/widgets.dart';
import 'package:temposcape_player/plugins/player_plugins.dart';

class OnlineRadiosPlugin extends BasePlayerPlugin {
  OnlineRadiosPlugin()
      : super(
          title: 'Online Radios',
          pluginTableInDatabase: 'pluginOnlineRadios',
          allowEmptySearch: true,
        );

  @override
  Widget buildSettingsMenu() {
    // TODO: implement buildSettingsMenu
    throw UnimplementedError();
  }

  @override
  Future<String> getSongUrl(String songUrl) {
    return Future<String>.value(songUrl);
  }

  @override
  Future<List<OnlineSong>> searchSong(String song, {int page = 1}) async {
    if (page > 1) return [];
    return <OnlineSong>[
      OnlineSong(
        title: 'r/a/dio',
        artist: 'Anison broadcasting',
        albumThumbnailUrl: 'https://r-a-d.io/assets/logo_image_small.png',
        songUrl: () => getSongUrl('https://stream.r-a-d.io/main.mp3'),
      ),
      OnlineSong(
        title: 'Eden of the West',
        artist: 'Anison broadcasting',
        albumThumbnailUrl:
            'https://www.edenofthewest.com/static/icons/production/apple-touch-icon.png',
        songUrl: () =>
            getSongUrl('https://www.edenofthewest.com/radio/8000/radio.mp3'),
      ),
      OnlineSong(
        title: 'AniSonFM',
        artist: 'Anison broadcasting',
        albumThumbnailUrl:
            'https://cdn-radiotime-logos.tunein.com/s185342q.png',
        albumArtUrl: 'http://anison.fm/images/main_maskot_spring.png',
        songUrl: () => getSongUrl('https://pool.anison.fm/AniSonFM(320)'),
      ),
      OnlineSong(
        title: 'LISTEN.moe',
        artist: 'Anison broadcasting',
        albumThumbnailUrl:
            'https://listen.moe/_nuxt/img/logo-square-64.248c1f3.png',
        albumArtUrl: 'https://listen.moe/_nuxt/img/logo-square-64.248c1f3.png',
        songUrl: () => getSongUrl('https://listen.moe/stream'),
      ),
    ];
  }
}
