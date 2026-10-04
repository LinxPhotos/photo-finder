import 'dart:typed_data';

enum MediaKind { image, video }

class DetectedMedia {
  const DetectedMedia(this.kind, this.extension);

  final MediaKind kind;
  final String extension;
}

class FileTypeDetector {
  static DetectedMedia? detect(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return const DetectedMedia(MediaKind.image, 'jpg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return const DetectedMedia(MediaKind.image, 'png');
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return const DetectedMedia(MediaKind.image, 'gif');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return const DetectedMedia(MediaKind.image, 'webp');
    }
    if (bytes.length >= 12) {
      final brand = String.fromCharCodes(bytes.sublist(4, 8)).toLowerCase();
      if (brand == 'ftyp') {
        final subtype = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
        if (subtype.startsWith('heic') ||
            subtype.startsWith('heif') ||
            subtype.startsWith('mif1')) {
          return const DetectedMedia(MediaKind.image, 'heic');
        }
        if (subtype.startsWith('mp4') ||
            subtype.startsWith('isom') ||
            subtype.startsWith('avc1') ||
            subtype.startsWith('3gp')) {
          return const DetectedMedia(MediaKind.video, 'mp4');
        }
        if (subtype.startsWith('qt')) {
          return const DetectedMedia(MediaKind.video, 'mov');
        }
      }
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return const DetectedMedia(MediaKind.video, 'mkv');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x41 &&
        bytes[9] == 0x56 &&
        bytes[10] == 0x49 &&
        bytes[11] == 0x20) {
      return const DetectedMedia(MediaKind.video, 'avi');
    }
    return null;
  }

  static String? extensionForMime(String? mime) {
    if (mime == null) return null;
    final lower = mime.toLowerCase();
    const map = {
      'image/jpeg': 'jpg',
      'image/jpg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/webp': 'webp',
      'image/heic': 'heic',
      'image/heif': 'heif',
      'video/mp4': 'mp4',
      'video/quicktime': 'mov',
      'video/x-matroska': 'mkv',
      'video/3gpp': '3gp',
      'video/webm': 'webm',
    };
    if (map.containsKey(lower)) return map[lower];
    if (lower.startsWith('image/')) {
      return lower.split('/').last;
    }
    if (lower.startsWith('video/')) {
      return lower.split('/').last;
    }
    return null;
  }
}
