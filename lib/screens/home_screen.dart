import 'package:flutter/material.dart';

import '../services/photo_platform.dart';
import 'scanner_screen.dart';
import 'share_save_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.platform});

  final PhotoPlatform platform;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkShares());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkShares();
    }
  }

  Future<void> _checkShares() async {
    final items = await widget.platform.takeSharePayloads();
    if (items.isEmpty || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShareSaveScreen(platform: widget.platform, items: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Finder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Download fixer and file renamer for photos and videos that saved without a proper name or extension.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan a download folder'),
              subtitle: const Text(
                'Find misnamed image and video files, preview fixes, then rename or copy with the right extension.',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ScannerScreen(platform: widget.platform),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share target'),
              subtitle: const Text(
                'Share from Google Photos to Photo Finder to save files using their display name.',
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Use Share in Google Photos and choose Photo Finder, or share again while this app is open.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
