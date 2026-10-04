import 'package:flutter/material.dart';

import '../services/file_type_detector.dart';
import '../services/photo_platform.dart';
import '../services/preferences_store.dart';
import '../services/rename_planner.dart';
import 'review_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.platform});

  final PhotoPlatform platform;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _prefs = PreferencesStore();
  String? _scanFolderUri;
  String? _scanFolderLabel;
  String? _outputFolderUri;
  String? _outputFolderLabel;
  bool _renameInPlace = true;
  bool _scanning = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uri = await _prefs.getLastScanFolderUri();
    final label = await _prefs.getLastScanFolderLabel();
    if (uri != null) {
      setState(() {
        _scanFolderUri = uri;
        _scanFolderLabel = label ?? 'Selected folder';
      });
    }
  }

  Future<void> _pickScanFolder() async {
    final folder = await widget.platform.pickScanFolder();
    if (folder == null) return;
    await _prefs.setLastScanFolder(folder.treeUri, folder.displayName);
    setState(() {
      _scanFolderUri = folder.treeUri;
      _scanFolderLabel = folder.displayName;
    });
  }

  Future<void> _pickOutputFolder() async {
    final folder = await widget.platform.pickOutputFolder();
    if (folder == null) return;
    setState(() {
      _outputFolderUri = folder.treeUri;
      _outputFolderLabel = folder.displayName;
      _renameInPlace = false;
    });
  }

  Future<void> _runScan() async {
    if (_scanFolderUri == null) {
      setState(() => _status = 'Pick a folder of downloaded files first.');
      return;
    }
    if (!_renameInPlace && _outputFolderUri == null) {
      setState(() => _status = 'Pick an output folder or choose rename in place.');
      return;
    }
    setState(() {
      _scanning = true;
      _status = 'Scanning…';
    });
    final entries = await widget.platform.listFolderFiles(_scanFolderUri!);
    final plans = <RenamePlan>[];
    var skipped = 0;
    for (final entry in entries) {
      final bytes = await widget.platform.readFileBytes(entry.uri);
      final detected = FileTypeDetector.detect(bytes);
      if (detected == null) {
        continue;
      }
      final plan = await RenamePlanner.planForFile(
        uri: entry.uri,
        displayName: entry.displayName,
        detected: detected,
        bytesForExif: bytes,
      );
      if (plan == null) {
        skipped++;
      } else {
        plans.add(plan);
      }
    }
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _status = plans.isEmpty
          ? 'No fixes needed. Skipped $skipped file(s) that already look fine.'
          : 'Found ${plans.length} file(s) to review. Skipped $skipped OK file(s).';
    });
    if (plans.isEmpty) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          platform: widget.platform,
          plans: plans,
          renameInPlace: _renameInPlace,
          outputTreeUri: _outputFolderUri,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _status = 'Renames applied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan & fix downloads')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pick a folder of files already saved on your device (for example a Google Photos download folder). '
            'Photo Finder detects images and videos by file content, not by searching your whole photo library.',
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Folder to scan'),
            subtitle: Text(_scanFolderLabel ?? 'Not selected'),
            trailing: const Icon(Icons.folder_open),
            onTap: _pickScanFolder,
          ),
          SwitchListTile(
            title: const Text('Rename in place'),
            subtitle: const Text('When off, copies fixed files into an output folder.'),
            value: _renameInPlace,
            onChanged: (value) {
              setState(() {
                _renameInPlace = value;
                if (value) {
                  _outputFolderUri = null;
                  _outputFolderLabel = null;
                }
              });
            },
          ),
          if (!_renameInPlace)
            ListTile(
              title: const Text('Output folder'),
              subtitle: Text(_outputFolderLabel ?? 'Not selected'),
              trailing: const Icon(Icons.drive_file_move),
              onTap: _pickOutputFolder,
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _scanning ? null : _runScan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_scanning ? 'Scanning…' : 'Scan folder'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!),
          ],
        ],
      ),
    );
  }
}
