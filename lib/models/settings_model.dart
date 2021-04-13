import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsModel extends ChangeNotifier {
  static final hiveBox = 'settings';

  static final _box = Hive.box<dynamic>(hiveBox);

  bool get darkMode => _box.get('darkMode', defaultValue: false);

  void setDarkMode(bool enabled) async {
    await _box.put('darkMode', enabled);
    notifyListeners();
  }
}
