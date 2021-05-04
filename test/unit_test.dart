// Import the test package and Counter class
import 'package:flutter_test/flutter_test.dart';
import 'package:temposcape_player/utils/duration_to_string.dart';
import 'package:temposcape_player/utils/hashing.dart';

void main() {
  group('Song hashing', () {
    test('Null song null source', () {
      expect(hashOnlineSong(), 'DA39A3EE5E');
    });

    test('Song with some id from Zing MP3', () {
      expect(hashOnlineSong(id: 'ZWZ9ZFIA', source: 'zingmp3'), '722A2E5AC4');
    });
    test('Song with some id and bitrate info from Zing MP3', () {
      expect(
          hashOnlineSong(
              id: 'ZWZ9ZFIA', source: 'zingmp3', additionalInfo: '320kbps'),
          '0B0EF5F393');
    });
  });

  group('Time formatter', () {
    test('Duration zero => 0:00', () {
      expect(
          getFormattedDuration(
            Duration.zero,
            timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
          ),
          '0:00');
    });

    test('Duration zero => 00:00', () {
      expect(
          getFormattedDuration(
            Duration.zero,
            timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
          ),
          '00:00');
    });

    test('Duration 0h0m0s999ms => 0:00', () {
      expect(
          getFormattedDuration(
            Duration(milliseconds: 999),
            timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
          ),
          '0:00');
    });

    test('Duration 0h0m0s1001ms => 0:01', () {
      expect(
          getFormattedDuration(
            Duration(milliseconds: 1001),
            timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
          ),
          '0:01');
    });

    test('Duration 0h0m0s1001ms => 0:00:01', () {
      expect(
          getFormattedDuration(
            Duration(milliseconds: 1001),
            timeFormat: TimeFormat.hours0Minutes0Seconds,
          ),
          '0:00:01');
    });

    test('Duration 0h0m0s1001ms => 00:00:01', () {
      expect(
          getFormattedDuration(
            Duration(milliseconds: 1001),
            timeFormat: TimeFormat.zeroHours0Minutes0Seconds,
          ),
          '00:00:01');
    });

    test('Duration 0h59m59s1001ms => 1:00:00', () {
      expect(
          getFormattedDuration(
            Duration(milliseconds: 1001, seconds: 59, minutes: 59),
            timeFormat: TimeFormat.optionalHours0Minutes0Seconds,
          ),
          '1:00:00');
    });
  });
}
