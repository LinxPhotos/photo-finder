import 'package:flutter/services.dart';

class PickedFolder {
  PickedFolder({required this.treeUri, required this.displayName});

  final String treeUri;
  final String displayName;

  factory PickedFolder.fromMap(Map<dynamic, dynamic> map) {
    return PickedFolder(
      treeUri: map['treeUri'] as String,
      displayName: map['displayName'] as String? ?? 'Folder',
    );
  }
}

class FolderEntry {
  FolderEntry({
    required this.uri,
    required this.displayName,
    required this.size,
  });

  final String uri;
  final String displayName;
  final int size;

  factory FolderEntry.fromMap(Map<dynamic, dynamic> map) {
    return FolderEntry(
      uri: map['uri'] as String,
      displayName: map['displayName'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShareItem {
  ShareItem({
    required this.uri,
    required this.mimeType,
    required this.displayName,
  });

  final String uri;
  final String? mimeType;
  final String? displayName;

  factory ShareItem.fromMap(Map<dynamic, dynamic> map) {
    return ShareItem(
      uri: map['uri'] as String,
      mimeType: map['mimeType'] as String?,
      displayName: map['displayName'] as String?,
    );
  }
}

class PhotoPlatform {
  PhotoPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.linxphotos.photo_finder/platform');

  final MethodChannel _channel;

  Future<PickedFolder?> pickScanFolder() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>?>('pickScanFolder');
    if (result == null) return null;
    return PickedFolder.fromMap(result);
  }

  Future<PickedFolder?> pickOutputFolder() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>?>('pickOutputFolder');
    if (result == null) return null;
    return PickedFolder.fromMap(result);
  }

  Future<PickedFolder?> pickSaveFolder() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>?>('pickSaveFolder');
    if (result == null) return null;
    return PickedFolder.fromMap(result);
  }

  Future<List<FolderEntry>> listFolderFiles(String treeUri) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'listFolderFiles',
      {'treeUri': treeUri},
    );
    return result?.map((e) => FolderEntry.fromMap(e as Map<dynamic, dynamic>)).toList() ??
        [];
  }

  Future<Uint8List> readFileBytes(String uri, {int maxBytes = 512 * 1024}) async {
    final result = await _channel.invokeMethod<Uint8List>(
      'readFileBytes',
      {'uri': uri, 'maxBytes': maxBytes},
    );
    return result ?? Uint8List(0);
  }

  Future<List<Map<String, dynamic>>> applyRenames({
    required List<RenameApplyItem> items,
    String? outputTreeUri,
  }) async {
    final payload = items
        .map(
          (item) => {
            'uri': item.uri,
            'newName': item.newName,
            'selected': item.selected,
          },
        )
        .toList();
    final result = await _channel.invokeMethod<List<dynamic>>(
      'applyRenames',
      {
        'items': payload,
        'outputTreeUri': outputTreeUri,
      },
    );
    return result?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  Future<Map<String, dynamic>> saveSharedFile({
    required String sourceUri,
    required String treeUri,
    required String fileName,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'saveSharedFile',
      {
        'sourceUri': sourceUri,
        'treeUri': treeUri,
        'fileName': fileName,
      },
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  Future<List<ShareItem>> takeSharePayloads() async {
    final result = await _channel.invokeMethod<List<dynamic>>('takeSharePayloads');
    return result?.map((e) => ShareItem.fromMap(e as Map<dynamic, dynamic>)).toList() ??
        [];
  }
}

class RenameApplyItem {
  RenameApplyItem({
    required this.uri,
    required this.newName,
    required this.selected,
  });

  final String uri;
  final String newName;
  final bool selected;
}
