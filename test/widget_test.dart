import 'package:flutter_test/flutter_test.dart';
import 'package:photo_finder/main.dart';

void main() {
  testWidgets('app shows Photo Finder title', (tester) async {
    await tester.pumpWidget(const PhotoFinderApp());
    expect(find.text('Photo Finder'), findsOneWidget);
  });
}
