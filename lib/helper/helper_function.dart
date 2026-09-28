import 'package:shared_preferences/shared_preferences.dart';

class HelperFunction {
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userThemeModeKey = "THEMEMODEKEY";

  static Future<bool?> getUserLoggedInStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(userLoggedInKey);
  }

  static Future<void> saveUserLoggedInStatus(bool loggedIn) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setBool(userLoggedInKey, loggedIn);
  }

  static Future<void> saveUserNameSF(String userName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setString(userNameKey, userName);
  }

  static Future<void> saveUserEmailSF(String userEmail) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setString(userEmailKey, userEmail);
  }

  static Future<void> clearUserData() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.remove(userLoggedInKey);
    await sf.remove(userNameKey);
    await sf.remove(userEmailKey);
  }

  static Future<String?> getUserNameSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);
  }

  static Future<String?> getUserEmailSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userEmailKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setString(userThemeModeKey, mode);
  }

  static Future<String> getThemeMode() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userThemeModeKey) ?? 'system';
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setBool('NOTIFICATIONS_ENABLED', enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool('NOTIFICATIONS_ENABLED') ?? true;
  }

  static Future<void> saveShowOnlineStatus(bool enabled) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setBool('SHOW_ONLINE_STATUS', enabled);
  }

  static Future<bool> getShowOnlineStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool('SHOW_ONLINE_STATUS') ?? true;
  }
}
