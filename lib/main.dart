import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/photo_platform.dart';

void main() {
  runApp(const PhotoFinderApp());
}

class PhotoFinderApp extends StatelessWidget {
  const PhotoFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(platform: PhotoPlatform()),
    );
  }
}
