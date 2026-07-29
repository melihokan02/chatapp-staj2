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

  /// Tema modu kaydet: 'light' | 'dark' | 'system'
  static Future<void> saveThemeMode(String mode) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    await sf.setString(userThemeModeKey, mode);
  }

  static Future<String> getThemeMode() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userThemeModeKey) ?? 'system';
  }
}