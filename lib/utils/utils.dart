import 'package:audio_service/audio_service.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

/// A discrete value that's a text representation of a duration.
///
/// It separates a duration into a component time quantity,
/// in which there's a most significant unit.
///
/// Syntax: `[optional|0|{none}]Unit`. Where:
///
/// * optional: quantity of unit isn't displayed if quantity = 0
/// * {none}: quantity of unit is displayed as 0 if quantity = 0, otherwise {quantity}
/// * 0 : pads an additional zero if quantity < 10
enum TimeFormat { optionalHours0Minutes0Seconds, optionalHoursMinutes0Seconds }

/// Display a duration as time intervals, separated by a colon.
///
/// `timeFormat`: the format of duration to be displayed
String getFormattedDuration(Duration duration,
    {TimeFormat timeFormat = TimeFormat.optionalHoursMinutes0Seconds}) {
  String hours = '';
  String minutes = '';
  String seconds = '';
  int clockHours = duration.inHours;
  int clockMinutes = duration.inMinutes % 60;
  int clockSeconds = duration.inSeconds % 60;

  switch (timeFormat) {
    case TimeFormat.optionalHours0Minutes0Seconds:
      if (duration == null) return '00:00';
      if (clockHours > 0) hours = '${clockHours.toString()}:';
      minutes = '${clockMinutes < 10 ? '0' : ''}${clockMinutes.toString()}:';
      seconds = '${clockSeconds < 10 ? '0' : ''}${clockSeconds.toString()}';
      break;
    case TimeFormat.optionalHoursMinutes0Seconds:
      if (duration == null) return '0:00';
      if (clockHours > 0) hours = '${clockHours.toString()}:';
      minutes = '${clockMinutes.toString()}:';
      seconds = '${clockSeconds < 10 ? '0' : ''}${clockSeconds.toString()}';
  }

  return '$hours$minutes$seconds';
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

MediaItem songInfoToMediaItem(SongInfo songInfo) => MediaItem(
      id: songInfo.id,
      album: songInfo.album,
      title: songInfo.title,
      artist: songInfo.artist,
// this.genre,
      duration: Duration(milliseconds: int.parse(songInfo.duration)),
      artUri: songInfo.albumArtwork,
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
