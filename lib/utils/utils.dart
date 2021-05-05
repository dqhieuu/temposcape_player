import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:temposcape_player/models/settings_model.dart';

import '../constants/constants.dart' as Constants;

export 'call_android_native.dart';
export 'duration_to_string.dart';
export 'song_type_conversion.dart';

void showSnackBar(BuildContext context,
    {@required String text, SnackBarAction action}) {
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(text),
    action: action,
    duration: const Duration(milliseconds: 800),
    // width: 280.0, // Width of the SnackBar.
    padding: const EdgeInsets.symmetric(
      horizontal: 8.0, // Inner padding for SnackBar content.
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
  ));
}

void showFirstTimeSelectionDialog(BuildContext context) {
  final settings = context.read<SettingsModel>();
  if (settings.hasSeenFirstTimeSelectionDialog) return;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          'Do you know?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.subtitle1,
            children: <InlineSpan>[
              TextSpan(
                  text:
                      'You have entered Selection mode. To display the action menu, press '),
              WidgetSpan(child: Icon(Icons.more_vert)),
              TextSpan(text: ' from the top right corner!'),
            ],
          ),
        ),
        actions: [
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Ok'),
          ),
        ],
      );
    },
  );

  settings.markFirstTimeSelectionDialogAsSeen();
}

String truncateText(String text, [int length = 20]) =>
    text.length <= length ? text : '$text...';

final _playlistNamesBox = Hive.box<String>(Constants.playlistNamesHiveBox);
String playlistName(PlaylistInfo playlist) =>
    _playlistNamesBox.get(playlist.name) ?? playlist.name;
