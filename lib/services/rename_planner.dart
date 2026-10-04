import 'package:exif/exif.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'file_type_detector.dart';

class RenamePlan {
  RenamePlan({
    required this.uri,
    required this.currentName,
    required this.proposedName,
    required this.reason,
    required this.detected,
    this.selected = true,
  });

  final String uri;
  final String currentName;
  String proposedName;
  final String reason;
  final DetectedMedia detected;
  bool selected;
}

class RenamePlanner {
  static final _uuid =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

  static bool isJunkBasename(String basename) {
    final base = p.basenameWithoutExtension(basename);
    if (base.isEmpty) return true;
    final lower = base.toLowerCase();
    const junk = {
      'download',
      'image',
      'img',
      'video',
      'videoplayback',
      'untitled',
      'file',
      'temp',
      'tmp',
    };
    if (junk.contains(lower)) return true;
    if (RegExp(r'^[0-9]+$').hasMatch(base)) return true;
    if (_uuid.hasMatch(base)) return true;
    if (RegExp(r'^\d{10,}$').hasMatch(base)) return true;
    return false;
  }

  static bool extensionMatches(String name, DetectedMedia detected) {
    final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty) return false;
    const aliases = {
      'jpeg': 'jpg',
      'tif': 'tiff',
      'heif': 'heic',
    };
    final normalized = aliases[ext] ?? ext;
    final target = aliases[detected.extension] ?? detected.extension;
    return normalized == target;
  }

  static bool looksFine(String name, DetectedMedia detected) {
    return !isJunkBasename(name) && extensionMatches(name, detected);
  }

  static Future<RenamePlan?> planForFile({
    required String uri,
    required String displayName,
    required DetectedMedia detected,
    required List<int> bytesForExif,
  }) async {
    if (looksFine(displayName, detected)) {
      return null;
    }
    final proposed = await _proposedName(displayName, detected, bytesForExif);
    final reasons = <String>[];
    if (!extensionMatches(displayName, detected)) {
      reasons.add('fix extension');
    }
    if (isJunkBasename(displayName)) {
      reasons.add('replace junk filename');
    }
    return RenamePlan(
      uri: uri,
      currentName: displayName,
      proposedName: proposed,
      reason: reasons.join(', '),
      detected: detected,
    );
  }

  static Future<String> _proposedName(
    String displayName,
    DetectedMedia detected,
    List<int> bytes,
  ) async {
    final ext = detected.extension;
    final useExifName =
        isJunkBasename(displayName) || p.extension(displayName).isEmpty;
    if (useExifName && detected.kind == MediaKind.image) {
      final fromExif = await _exifTimestampName(bytes, ext);
      if (fromExif != null) return fromExif;
    }
    var base = p.basenameWithoutExtension(displayName);
    if (base.isEmpty || isJunkBasename(displayName)) {
      base = 'media';
    }
    base = _sanitize(base);
    return '$base.$ext';
  }

  static Future<String?> _exifTimestampName(List<int> bytes, String ext) async {
    try {
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) return null;
      final raw = data['EXIF DateTimeOriginal']?.printable ??
          data['Image DateTime']?.printable;
      if (raw == null || raw.isEmpty) return null;
      final format = DateFormat('yyyy:MM:dd HH:mm:ss');
      final parsed = format.tryParse(raw);
      if (parsed == null) return null;
      return 'IMG_${DateFormat('yyyyMMdd_HHmmss').format(parsed.toLocal())}.$ext';
    } catch (_) {
      return null;
    }
  }

  static String _sanitize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'media' : cleaned;
  }
}
