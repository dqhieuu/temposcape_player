import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

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
  final bool allowEmptySearch;
  Widget icon;

  BasePlayerPlugin(
      {@required this.title,
      @required this.pluginTableInDatabase,
      this.icon,
      this.allowEmptySearch = false}) {
    Hive.openBox(pluginTableInDatabase);
  }

  T getValueFromDatabase<T>(String key) {
    return Hive.box(pluginTableInDatabase).get(key);
  }

  Future<void> putValueToDatabase<T>(String key, T value) {
    return Hive.box(pluginTableInDatabase).put(key, value);
  }

  Widget buildSettingsMenu();
  Future<List<OnlineSong>> searchSong(String song, {int page});
  Future<String> getSongUrl(String songId);
}
