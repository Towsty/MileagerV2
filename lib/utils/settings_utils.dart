import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsUtils {
  static Future<bool> getDebugTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('debug_tracking_enabled') ?? false;
  }

  static Future<void> setDebugTrackingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_tracking_enabled', value);
  }

  static Future<String> getReportSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('report_save_path');

    if (savedPath != null && await Directory(savedPath).exists()) {
      return savedPath;
    }

    // Default to Documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    return documentsDir.path;
  }

  static Future<void> setReportSavePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('report_save_path', path);
  }

  static Future<bool> getAutoReportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_report_enabled') ?? true;
  }

  static Future<void> setAutoReportEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_report_enabled', value);
  }
}
