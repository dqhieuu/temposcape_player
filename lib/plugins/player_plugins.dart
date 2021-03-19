import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class NetworkSong {
  String id;
  String albumArtUrl;
  String albumThumbnailUrl;
  String title;
  String artist;
  NetworkSong(
      {this.id,
      this.albumArtUrl,
      this.title,
      this.artist,
      this.albumThumbnailUrl});
}

abstract class BasePlayerPlugin {
  final String title;
  final String pluginTableInDatabase;
  Image icon;

  BasePlayerPlugin(
      {@required this.title, @required this.pluginTableInDatabase, this.icon});

  T getValueFromDatabase<T>(String key) {
    return Hive.box(pluginTableInDatabase).get(key);
  }

  void putValueToDatabase<T>(String key, T value) {
    Hive.box(pluginTableInDatabase).put(key, value);
  }

  Widget buildSettingsMenu();
  Future<List<NetworkSong>> searchSong(String song, {int page});
  Future<String> getSongUrl(NetworkSong song);
}

// var response = await http.get(
//     'https://www.nhaccuatui.com/download/song/2EZQ35BpVH0U_128',
//     headers: {
//       HttpHeaders.refererHeader:
//           'https://www.nhaccuatui.com/',
//     });
// print(response.body);

class ZingMp3Plugin extends BasePlayerPlugin {
  static const sha512SecretKey = r'882QcNXV4tUZbvAsjmFOHqNC1LpcBRKW';
  static const zingMp3ApiKey = r'kI44ARvPwaqL7v0KuDSM0rGORtdY1nnw';
  static const cookieRqid =
      r'MHwxODMdUngODAdUngMjMxLjY3fHYxLjEdUngMXwxNjE2MDkyMTg2NDQw';
  static const version = '1.1.1';

  ZingMp3Plugin()
      : super(
            title: 'Zing Mp3 plugin', pluginTableInDatabase: 'pluginZingMp3') {
    Hive.openBox(pluginTableInDatabase);
  }

  get ctime => (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

  bool _cookieExpired() {
    // final time = getValueFromDatabase<DateTime>('cookieExpirationDate');
    // if (time == null) return true;
    // // return DateTime.now().difference(time).inDays < 2;

    // final cookie = getValueFromDatabase<String>('cookie');
    // if (cookie == null) return true;
    // TODO: implement a cookie date parser
  }

  Future<String> _getNewCookie() async {
    final response = await http.get(Uri.https('zingmp3.vn', ''));
    final cookie = response.headers[HttpHeaders.setCookieHeader];

    return cookie;
  }

  Future<String> _renewCookie() async {
    final response = await http.get(Uri.https('zingmp3.vn', ''));
    final newCookie = response.headers[HttpHeaders.setCookieHeader];

    if (newCookie != null) {
      putValueToDatabase<String>('cookie', newCookie);
    }

    return newCookie;
  }

  String _getSearchSignature(int page) {
    final infoLeft = '/api/v2/search';
    final count = 18;
    var infoRight = sha256
        .convert(utf8.encode(
            'count=${count.toString()}ctime=${ctime}page=${page.toString()}type=songversion=$version'))
        .toString();
    var signature = Hmac(sha512, utf8.encode(sha512SecretKey))
        .convert(utf8.encode(infoLeft + infoRight))
        .toString();
    return signature;
  }

  String _getSongSignature(String songId) {
    var info1 = [
      '/api/v2/song/getStreaming',
      '/api/v2/search',
    ];
    var info2 = [
      'ctime=1616043492id=ZW9C67BIversion=1.1.1',
      'count=18ctime=1616043493page=1type=songversion=1.1.1',
    ];

    final infoLeft = '/api/v2/song/getStreaming';
    final infoRight = sha256
        .convert(utf8.encode('ctime=${ctime}id=${songId}version=$version'))
        .toString();
    final signature = Hmac(sha512, utf8.encode(sha512SecretKey))
        .convert(utf8.encode(infoLeft + infoRight))
        .toString();
    return signature;
  }

  @override
  Future<List<NetworkSong>> searchSong(String song, {int page = 1}) async {
    final cookie = await _renewCookie();

    final response = await http.get(
        Uri.https('zingmp3.vn', 'api/v2/search', {
          'q': song,
          'type': 'song',
          'page': page.toString(),
          'count': '18',
          'ctime': ctime,
          'version': version,
          'sig': _getSearchSignature(page),
          'apiKey': zingMp3ApiKey,
        }),
        headers: {
          'Cookie': RegExp(r'zmp3_rqid=(\w+)').firstMatch(cookie).group(0),
        });
    final result = json.decode(response.body);
    var songList = <NetworkSong>[];
    if (result['msg'] == 'Success') {
      (result['data']['items'] as List).forEach((e) {
        songList.add(
          NetworkSong(
            id: e['encodeId'],
            title: e['title'],
            artist: e['artistsNames'],
            albumThumbnailUrl: e['thumbnail'],
          ),
        );
      });
    }
    return songList;
  }

  @override
  Widget buildSettingsMenu() {
    // TODO: implement buildSettingsMenu
    throw UnimplementedError();
  }

  @override
  Future<String> getSongUrl(NetworkSong song) {
    // TODO: implement getSong
    throw UnimplementedError();
  }
}
