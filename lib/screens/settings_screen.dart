import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:temposcape_player/models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: SettingsList(
            backgroundColor: Theme.of(context).canvasColor,
            sections: [
              SettingsSection(
                title: 'General',
                tiles: [
                  SettingsTile(
                    title: 'Language',
                    subtitle: 'English',
                    leading: Icon(Icons.language),
                    onPressed: (BuildContext context) {},
                  ),
                  SettingsTile.switchTile(
                    title: 'Dark mode',
                    leading: Icon(Icons.nights_stay_rounded),
                    switchValue: settings.darkMode,
                    onToggle: (bool value) {
                      settings.setDarkMode(value);
                    },
                  ),
                ],
              ),
              // SettingsSection(
              //   title: 'Plugins',
              //   tiles: [
              //     SettingsTile.switchTile(
              //       title: 'ABC',
              //       leading: Icon(Icons.looks_one_outlined),
              //       switchValue: settings.darkMode,
              //       onToggle: (bool value) {
              //         settings.setDarkMode(value);
              //       },
              //     ),
              //   ],
              // ),
            ]),
      ),
    );
  }
}
