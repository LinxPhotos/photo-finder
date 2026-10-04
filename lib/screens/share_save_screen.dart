import 'package:flutter/material.dart';

import '../services/photo_platform.dart';
import '../services/preferences_store.dart';
import '../services/share_filename.dart';

class ShareSaveScreen extends StatefulWidget {
  const ShareSaveScreen({
    super.key,
    required this.platform,
    required this.items,
  });

  final PhotoPlatform platform;
  final List<ShareItem> items;

  @override
  State<ShareSaveScreen> createState() => _ShareSaveScreenState();
}

class _ShareSaveScreenState extends State<ShareSaveScreen> {
  final _prefs = PreferencesStore();
  String? _saveFolderUri;
  String? _saveFolderLabel;
  bool _saving = false;
  late final List<_ShareRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.items
        .map(
          (item) => _ShareRow(
            item: item,
            fileName: resolveShareFileName(
              displayName: item.displayName,
              mimeType: item.mimeType,
            ),
          ),
        )
        .toList();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uri = await _prefs.getSaveFolderUri();
    final label = await _prefs.getSaveFolderLabel();
    if (uri != null) {
      setState(() {
        _saveFolderUri = uri;
        _saveFolderLabel = label ?? 'Save folder';
      });
    }
  }

  Future<void> _pickSaveFolder() async {
    final folder = await widget.platform.pickSaveFolder();
    if (folder == null) return;
    await _prefs.setSaveFolder(folder.treeUri, folder.displayName);
    setState(() {
      _saveFolderUri = folder.treeUri;
      _saveFolderLabel = folder.displayName;
    });
  }

  Future<void> _saveAll() async {
    if (_saveFolderUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a save folder first.')),
      );
      return;
    }
    setState(() => _saving = true);
    var saved = 0;
    for (final row in _rows) {
      if (!row.selected) continue;
      try {
        await widget.platform.saveSharedFile(
          sourceUri: row.item.uri,
          treeUri: _saveFolderUri!,
          fileName: row.fileName,
        );
        saved++;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save ${row.fileName}')),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $saved file(s).')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save shared media')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Incoming shares from Google Photos use the display name when saving. '
            'If the name has no extension, Photo Finder adds one from the MIME type.',
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Save folder'),
            subtitle: Text(_saveFolderLabel ?? 'Not selected'),
            trailing: const Icon(Icons.folder),
            onTap: _pickSaveFolder,
          ),
          const Divider(),
          ..._rows.map(
            (row) => CheckboxListTile(
              value: row.selected,
              onChanged: (value) => setState(() => row.selected = value ?? true),
              title: Text(row.fileName),
              subtitle: Text(row.item.mimeType ?? 'unknown type'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveAll,
            child: Text(_saving ? 'Saving…' : 'Save to folder'),
          ),
        ],
      ),
    );
  }
}

class _ShareRow {
  _ShareRow({required this.item, required this.fileName});

  final ShareItem item;
  String fileName;
  bool selected = true;
}
