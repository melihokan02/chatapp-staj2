import 'package:chatapp/helper/helper_function.dart';
import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  String? _currentUserEmail;
  String? _currentUserName;
  ThemeMode _themeMode = ThemeMode.system;

  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadUser() async {
    _currentUserEmail = await HelperFunction.getUserEmailSF();
    _currentUserName = await HelperFunction.getUserNameSF();
    final savedMode = await HelperFunction.getThemeMode();
    _themeMode = _parsThemeMode(savedMode);
    notifyListeners();
  }

  void setUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
    notifyListeners();
  }

  void clearUser() {
    _currentUserEmail = null;
    _currentUserName = null;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await HelperFunction.saveThemeMode(modeStr);
    notifyListeners();
  }

  ThemeMode _parsThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
