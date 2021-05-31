import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:temposcape_player/plugins/player_plugins.dart';

/// Plugin for getting songs in Zing Mp3.
/// Zing Mp3 has its own API but it needs a cookie and a signature to
/// be able to use it (encrypted and liable to change).
///
/// [_getSearchSignature()], [_getSongSignature()] return the signature
/// magically (might not work in the future).
class ZingMp3Plugin extends BasePlayerPlugin {
  static const sha512SecretKey = r'882QcNXV4tUZbvAsjmFOHqNC1LpcBRKW';
  static const zingMp3ApiKey = r'kI44ARvPwaqL7v0KuDSM0rGORtdY1nnw';
  static const version = '1.2.6';

  String cookie;

  ZingMp3Plugin()
      : super(title: 'Zing MP3', pluginTableInDatabase: 'pluginZingMp3');

  /// Unix timestamp in seconds.
  get ctime => (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

  bool _cookieExpired() {
    // final time = getValueFromDatabase<DateTime>('cookieExpirationDate');
    // if (time == null) return true;
    // // return DateTime.now().difference(time).inDays < 2;

    // final cookie = getValueFromDatabase<String>('cookie');
    // if (cookie == null) return true;
    // TODO: implement a cookie date parser. WE ARE NOT BEING EFFICIENT !
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
    const infoLeft = '/api/v2/search';
    const count = 18;
    var infoRight = sha256
        .convert(utf8.encode(
            'count=${count.toString()}ctime=${ctime}page=${page.toString()}type=songversion=$version'))
        .toString();
    var signature = Hmac(sha512, utf8.encode(sha512SecretKey))
        .convert(utf8.encode(infoLeft + infoRight))
        .toString();
    return signature;
  }

  /// Signature = Hmac sha512 of (
  ///   '/api/v2/song/getStreaming' +
  ///
  ///   sha256 of ('ctime=_CURRENTTIMESTAMP_id=_SONGID_version=_CURRENTVERSION_')
  ///
  /// ), with key = SECRET_KEY
  String _getSongSignature(String songId) {
    const infoLeft = '/api/v2/song/getStreaming';
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
    if (cookie == null) {
      cookie = await _renewCookie();
    }

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
          ?.where((e) => e['streamingStatus'] as int != 2)
          ?.forEach((e) {
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
    if (cookie == null) {
      cookie = await _renewCookie();
    }

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
    // Last value usually is of best quality.
    return songUrlList.values.toList().last;
  }
}
