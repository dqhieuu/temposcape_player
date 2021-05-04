import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:temposcape_player/models/settings_model.dart';
import 'package:temposcape_player/plugins/player_plugins.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final plugins = context.read<List<BasePlayerPlugin>>();

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
              SettingsSection(
                title: 'Plugins',
                tiles: plugins
                    .map(
                      (plugin) => SettingsTile.switchTile(
                        title: plugin.title,
                        leading: plugin.icon ?? Icon(Icons.album_rounded),
                        switchValue:
                            plugin.getValueFromDatabase<bool>('enabled') ??
                                true,
                        onToggle: (bool value) async {
                          await plugin.putValueToDatabase<bool>(
                              'enabled', value);
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ]),
      ),
    );
  }
}
