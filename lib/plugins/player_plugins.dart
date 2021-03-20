import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// An online song represents a song with information fetched from the Internet.
///
/// Since getting a url to the actual song usually isn't instantaneous and
/// needs to be fetched from the remote site, a callback function
/// that fetches the song url should be passed to `songUrl` instead.
///
/// * albumThumbnailUrl: Thumbnail-size album cover url, is used when
/// displaying a list of searched song. Should not be null.
/// * albumArtUrl: Regular size album cover url, is used in the main player
/// and the mini player. If null, player will use the thumbnail url instead.
class OnlineSong {
  String id;
  String albumArtUrl;
  String albumThumbnailUrl;
  String title;
  String artist;
  String fromPlugin;
  Future<String> Function() songUrl;
  OnlineSong({
    this.id,
    this.albumArtUrl,
    this.title,
    this.artist,
    this.albumThumbnailUrl,
    this.songUrl,
  });
}

/// A player plugin is an object which provides the ability to search
/// and get songs from a particular site.
///
/// This abstract class defines a template for methods required
/// to integrate the plugin into the application. It also provides
/// methods for getting/putting data from the specified table in the database.
///
/// Child constructor must call parent constructor with these required parameters:
/// * [title]: The plugin title to be displayed in some place in the app.
/// * [pluginTableInDatabase]: Name of the table containing all plugin information,
/// also where the database methods query.
///
/// Constructor can optionally provide:
/// * [icon]: The plugin icon to be displayed in some place in the app
///
/// Methods:
/// * [buildSettingsMenu()]: Returns a menu widget for displaying in the settings page
abstract class BasePlayerPlugin {
  final String title;
  final String pluginTableInDatabase;
  Image icon;

  BasePlayerPlugin(
      {@required this.title, @required this.pluginTableInDatabase, this.icon}) {
    Hive.openBox(pluginTableInDatabase);
  }

  T getValueFromDatabase<T>(String key) {
    return Hive.box(pluginTableInDatabase).get(key);
  }

  void putValueToDatabase<T>(String key, T value) {
    Hive.box(pluginTableInDatabase).put(key, value);
  }

  Widget buildSettingsMenu();
  Future<List<OnlineSong>> searchSong(String song, {int page});
  Future<String> getSongUrl(String songId);
}

// var response = await http.get(
//     'https://www.nhaccuatui.com/download/song/2EZQ35BpVH0U_128',
//     headers: {
//       HttpHeaders.refererHeader:
//           'https://www.nhaccuatui.com/',
//     });
// print(response.body);

/// Plugin for getting songs in Zing Mp3.
/// Zing Mp3 has its own API but it needs a cookie and a signature to
/// be able to use it (encrypted and liable to change).
///
/// [_getSearchSignature()], [_getSongSignature()] return the signature
/// magically (might not work in the future).
class ZingMp3Plugin extends BasePlayerPlugin {
  static const sha512SecretKey = r'882QcNXV4tUZbvAsjmFOHqNC1LpcBRKW';
  static const zingMp3ApiKey = r'kI44ARvPwaqL7v0KuDSM0rGORtdY1nnw';
  static const version = '1.1.3';

  ZingMp3Plugin()
      : super(title: 'Zing Mp3 plugin', pluginTableInDatabase: 'pluginZingMp3');

  /// Unix timestamp in seconds.
  get ctime => (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

  bool _cookieExpired() {
    // final time = getValueFromDatabase<DateTime>('cookieExpirationDate');
    // if (time == null) return true;
    // // return DateTime.now().difference(time).inDays < 2;

    // final cookie = getValueFromDatabase<String>('cookie');
    // if (cookie == null) return true;
    // TODO: implement a cookie date parser. WE ARE SENDING A REQUEST TO GET THE COOKIE PRE- EVERY SINGLE REQUEST !!!
  }

  Future<String> _renewCookie() async {
    final response = await http.get(Uri.https('zingmp3.vn', ''));
    final newCookie = response.headers[HttpHeaders.setCookieHeader];
    Hive.box('pluginZingMp3').clear();
    if (newCookie != null) {
      putValueToDatabase<String>('cookie', newCookie);
    }

    return newCookie;
  }

  /// Signature = Hmac sha512 of (
  ///   '/api/v2/search' +
  ///
  ///   sha256 of ('count=18ctime=_CURRENTTIMESTAMP_page=_PAGETOSEARCH_type=songversion=_CURRENTVERSION_')
  ///
  /// ), with key = SECRET_KEY
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
  Future<List<OnlineSong>> searchSong(String song, {int page = 1}) async {
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
          // Get only zmp3_rqid part of cookie.
          'Cookie': RegExp(r'zmp3_rqid=(\w+)').firstMatch(cookie).group(0),
        });
    final result = json.decode(response.body);
    var songList = <OnlineSong>[];
    if (result['msg'] == 'Success') {
      (result['data']['items'] as List)
          // Where song is not VIP content.
          .where((e) => e['streamingStatus'] as int != 2)
          .forEach((e) {
        songList.add(
          OnlineSong(
              id: e['encodeId'],
              title: e['title'],
              artist: e['artistsNames'],
              albumThumbnailUrl: e['thumbnail'],
              albumArtUrl: e['thumbnailM'] ?? e['thumbnail'],
              songUrl: () => getSongUrl(e['encodeId'] as String)),
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
  Future<String> getSongUrl(String songId) async {
    final cookie = await _renewCookie();

    final response = await http.get(
        Uri.https('zingmp3.vn', 'api/v2/song/getStreaming', {
          'id': songId,
          'ctime': ctime,
          'version': version,
          'sig': _getSongSignature(songId),
          'apiKey': zingMp3ApiKey,
        }),
        headers: {
          'Cookie': RegExp(r'zmp3_rqid=(\w+)').firstMatch(cookie).group(0),
        });

    final songUrlList = (json.decode(response.body)['data']
        as Map<String, dynamic>)
      ..removeWhere((key, value) => !value.startsWith('http'));
    // Last value usually is of best quality. Probably... Maybe... Only if map's keys somehow is ordered... I'm not sure...
    return songUrlList.values.toList().last;
  }
}
