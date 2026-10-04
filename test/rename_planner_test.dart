import 'package:flutter_test/flutter_test.dart';
import 'package:photo_finder/services/file_type_detector.dart';
import 'package:photo_finder/services/rename_planner.dart';

void main() {
  test('junk download basename is flagged', () {
    expect(RenamePlanner.isJunkBasename('download'), isTrue);
    expect(RenamePlanner.isJunkBasename('vacation.jpg'), isFalse);
  });

  test('skips files that already look fine', () async {
    final detected = const DetectedMedia(MediaKind.image, 'jpg');
    expect(RenamePlanner.looksFine('IMG_0001.jpg', detected), isTrue);
    final plan = await RenamePlanner.planForFile(
      uri: 'content://test/1',
      displayName: 'IMG_0001.jpg',
      detected: detected,
      bytesForExif: const [],
    );
    expect(plan, isNull);
  });

  test('proposes extension fix for extensionless JPEG', () async {
    final detected = const DetectedMedia(MediaKind.image, 'jpg');
    final plan = await RenamePlanner.planForFile(
      uri: 'content://test/2',
      displayName: '1234567890',
      detected: detected,
      bytesForExif: const [],
    );
    expect(plan, isNotNull);
    expect(plan!.proposedName.endsWith('.jpg'), isTrue);
  });
}
