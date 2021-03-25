import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:temposcape_player/plugins/player_plugins.dart';

/// The official API doesn't work, which is why we're using the internal,
/// undocumented SoundCloud API. Kudos to the youtube-dl contributors
/// for figuring out how to use this internal API.
/// https://github.com/ytdl-org/youtube-dl/blob/master/youtube_dl/extractor/soundcloud.py
class SoundCloudPlugin extends BasePlayerPlugin {
  static const soundCloudClientId = r'SHBP59ZbnkOWhy3perfU0I83tRB8UuJk';

  SoundCloudPlugin()
      : super(title: 'SoundCloud', pluginTableInDatabase: 'pluginSoundCloud');

  @override
  Widget buildSettingsMenu() {
    // TODO: implement buildSettingsMenu
    throw UnimplementedError();
  }

  /// This is kind of hard to parse.
  ///
  /// First, we have the song id. Using that id, we can get to the
  /// [songInfoPage] which contains several types of urls
  /// to the streamable/downloadable urls.
  ///
  /// How do we choose the best stream type? We follow this one rule:
  /// the url we select should point to a media file, as opposed to a media stream,
  /// because we don't want to deal with media streams. Therefore, we select
  /// any available media file url(progressive), if there's none, we
  /// default to selecting the first url(hls).
  ///
  /// Second, the [preferedSongPageUrl] we are having now doesn't link to the
  /// media file, but links to a json file containing the url of the file we need.
  ///
  /// Thus, we have this route [songId] -> [songInfoPage] -> [preferedSongPageUrl]
  /// -> [songPage] -> [songUrl].
  @override
  Future<String> getSongUrl(String songId) async {
    if (songId == null) return null;

    final songInfoPage = await http.get(
      Uri.https('api-v2.soundcloud.com', 'tracks/$songId', {
        'client_id': soundCloudClientId,
      }),
    );

    List songStreamLinks =
        json.decode(songInfoPage.body)['media']['transcodings'];

    String preferedSongPageUrl = songStreamLinks.first['url'];

    for (Map element in songStreamLinks) {
      if (element['format']['protocol'].toString().toLowerCase() ==
          'progressive') {
        preferedSongPageUrl = element['url'];
        break;
        // Has found an mp3 link.
      }
    }

    final songPage =
        await http.get('${preferedSongPageUrl}?client_id=$soundCloudClientId');
    final songUrl = json.decode(songPage.body)['url'];
    return songUrl;
  }

  @override
  Future<List<OnlineSong>> searchSong(String song, {int page = 1}) async {
    const itemsPerPage = 20;

    final response = await http.get(
      Uri.https('api-v2.soundcloud.com', 'search/tracks', {
        'client_id': soundCloudClientId,
        'q': song,
        'limit': itemsPerPage.toString(),
        'offset': ((page - 1) * itemsPerPage).toString(),
      }),
    );

    List elems = json.decode(response.body)['collection'];
    final songs = elems.map<OnlineSong>(
      (e) {
        final songId = e['id']?.toString();
        return OnlineSong(
            id: songId ?? '',
            title: e['title'] ?? '',
            artist: (e['publisher_metadata'] ?? const {})['artist'] ?? '',
            albumThumbnailUrl: e['artwork_url'],
            songUrl: () => getSongUrl(songId));
      },
    );
    return songs.toList();
  }
}
