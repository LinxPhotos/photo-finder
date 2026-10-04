import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStore {
  static const _saveFolderKey = 'default_save_folder_uri';
  static const _saveFolderLabelKey = 'default_save_folder_label';
  static const _lastScanFolderKey = 'last_scan_folder_uri';
  static const _lastScanFolderLabelKey = 'last_scan_folder_label';

  Future<String?> getSaveFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_saveFolderKey);
  }

  Future<String?> getSaveFolderLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_saveFolderLabelKey);
  }

  Future<void> setSaveFolder(String uri, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveFolderKey, uri);
    await prefs.setString(_saveFolderLabelKey, label);
  }

  Future<String?> getLastScanFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastScanFolderKey);
  }

  Future<String?> getLastScanFolderLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastScanFolderLabelKey);
  }

  Future<void> setLastScanFolder(String uri, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScanFolderKey, uri);
    await prefs.setString(_lastScanFolderLabelKey, label);
  }
}
