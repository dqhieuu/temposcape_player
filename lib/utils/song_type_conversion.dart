import 'package:audio_service/audio_service.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

// Using library-defined data types was a PITA!
// This serves as adapters that helps bridge data between packages.

MediaItem songInfoToMediaItem(SongInfo songInfo) => MediaItem(
      id: songInfo.id,
      album: songInfo.album,
      title: songInfo.title,
      artist: songInfo.artist,
      // this.genre,
      duration: Duration(milliseconds: int.parse(songInfo.duration)),
      artUri: songInfo.albumArtwork != null
          ? Uri.file(songInfo.albumArtwork).toString()
          : null,
      // this.playable = true,
      displayTitle: songInfo.title,
      displaySubtitle: songInfo.artist,
      // this.displayDescription,
      // this.rating,
      extras: SongExtraInfo(
        filePath: songInfo.filePath,
        uri: songInfo.uri,
        track: songInfo.track,
        albumId: songInfo.albumId,
        artistId: songInfo.artistId,
        displayName: songInfo.displayName,
        year: songInfo.year,
        bookmark: songInfo.bookmark,
        composer: songInfo.composer,
        fileSize: songInfo.fileSize,
        isPodcast: songInfo.isPodcast,
        isAlarm: songInfo.isAlarm,
        isMusic: songInfo.isMusic,
        isNotification: songInfo.isNotification,
        isRingtone: songInfo.isRingtone,
        isOnline: false,
      ).toMap(),
    );

SongInfo mediaItemToSongInfo(MediaItem mediaItem) {
  var returnSong = SongInfo(
    albumId: mediaItem.extras['albumId'],
    artistId: mediaItem.extras['artistId'],
    artist: mediaItem.artist,
    album: mediaItem.album,
    title: mediaItem.title,
    displayName: mediaItem.extras['displayName'],
    composer: mediaItem.extras['composer'],
    year: mediaItem.extras['year'],
    track: mediaItem.extras['track'],
    duration: mediaItem.duration.inMilliseconds.toString(),
    bookmark: mediaItem.extras['bookmark'],
    filePath: mediaItem.extras['filePath'],
    uri: mediaItem.extras['uri'],
    fileSize: mediaItem.extras['fileSize'],
    albumArtwork:
        mediaItem.artUri != null ? Uri.parse(mediaItem.artUri).path : null,
    isMusic: mediaItem.extras['isMusic'],
    isPodcast: mediaItem.extras['isPodcast'],
    isRingtone: mediaItem.extras['isRingtone'],
    isAlarm: mediaItem.extras['isAlarm'],
    isNotification: mediaItem.extras['isNotification'],
  );
  returnSong.id = mediaItem.id;
  return returnSong;
}

class SongExtraInfo {
  String filePath;
  String uri;
  String track;
  String albumId;
  String artistId;
  String displayName;
  String year;
  String bookmark;
  String composer;
  String fileSize;
  bool isPodcast;
  bool isAlarm;
  bool isMusic;
  bool isNotification;
  bool isRingtone;
  bool isOnline;

  SongExtraInfo(
      {this.filePath,
      this.uri,
      this.track,
      this.albumId,
      this.artistId,
      this.displayName,
      this.year,
      this.bookmark,
      this.composer,
      this.fileSize,
      this.isPodcast = false,
      this.isAlarm = false,
      this.isMusic = false,
      this.isNotification = false,
      this.isRingtone = false,
      this.isOnline = false});
  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'uri': uri,
      'track': track,
      'albumId': albumId,
      'artistId': artistId,
      'displayName': displayName,
      'year': year,
      'bookmark': bookmark,
      'composer': composer,
      'fileSize': fileSize,
      'isPodcast': isPodcast,
      'isAlarm': isAlarm,
      'isMusic': isMusic,
      'isNotification': isNotification,
      'isRingtone': isRingtone,
      'isOnline': isOnline,
    };
  }
}
