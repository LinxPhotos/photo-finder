import 'package:path/path.dart' as p;

import 'file_type_detector.dart';

String resolveShareFileName({
  required String? displayName,
  required String? mimeType,
}) {
  var name = (displayName ?? 'download').trim();
  if (name.isEmpty) {
    name = 'download';
  }
  name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  if (p.extension(name).isEmpty) {
    final ext = FileTypeDetector.extensionForMime(mimeType) ?? 'jpg';
    name = '$name.$ext';
  }
  return name;
}

bool shareNameNeedsExtensionFix(String? displayName) {
  if (displayName == null || displayName.isEmpty) return true;
  return p.extension(displayName).isEmpty;
}
