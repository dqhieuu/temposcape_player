import 'package:flutter_audio_query/flutter_audio_query.dart';

class MutableSongInfo {
  factory MutableSongInfo.fromSongInfo(SongInfo songInfo) {
    if (songInfo == null) return null;
    return MutableSongInfo(
        albumId: songInfo.albumId,
        artistId: songInfo.artistId,
        artist: songInfo.artist,
        album: songInfo.album,
        title: songInfo.title,
        displayName: songInfo.displayName,
        composer: songInfo.composer,
        year: songInfo.year,
        track: songInfo.track,
        duration: songInfo.duration,
        bookmark: songInfo.bookmark,
        filePath: songInfo.filePath,
        uri: songInfo.uri,
        fileSize: songInfo.fileSize,
        albumArtwork: songInfo.albumArtwork,
        isMusic: songInfo.isMusic,
        isPodcast: songInfo.isPodcast,
        isRingtone: songInfo.isRingtone,
        isAlarm: songInfo.isAlarm,
        isNotification: songInfo.isNotification);
  }

  MutableSongInfo(
      {this.albumId,
      this.artistId,
      this.artist,
      this.album,
      this.title,
      this.displayName,
      this.composer,
      this.year,
      this.track,
      this.duration,
      this.bookmark,
      this.filePath,
      this.uri,
      this.fileSize,
      this.albumArtwork,
      this.isMusic,
      this.isPodcast,
      this.isRingtone,
      this.isAlarm,
      this.isNotification});

  /// Returns the album id which this song appears.
  String albumId;

  /// Returns the artist id who create this audio file.
  String artistId;

  /// Returns the artist name who create this audio file.
  String artist;

  /// Returns the album title which this song appears.
  String album;

  // ///Returns the genre name which this song belongs.
  // String genre;

  /// Returns the song title.
  String title;

  /// Returns the song display name. Display name string
  /// is a combination of [Track number] + [Song title] [File extension]
  /// Something like 1 My pretty song.mp3
  String displayName;

  /// Returns the composer name of this song.
  String composer;

  /// Returns the year of this song was created.
  String year;

  /// Returns the album track number if this song has one.
  String track;

  /// Returns a String with a number in milliseconds (ms) that is the duration of this audio file.
  String duration;

  /// Returns in ms, playback position when this song was stopped.
  /// from the last time.
  String bookmark;

  /// Returns a String with a file path to audio data file
  String filePath;

  String uri;

  /// Returns a String with the size, in bytes, of this audio file.
  String fileSize;

  ///Returns album artwork path which current song appears.
  String albumArtwork;

  bool isMusic;

  bool isPodcast;

  bool isRingtone;

  bool isAlarm;

  bool isNotification;
}
