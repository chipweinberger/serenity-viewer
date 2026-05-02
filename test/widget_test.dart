import 'package:flutter_test/flutter_test.dart';

import 'package:serenity_viewer/main.dart';

void main() {
  testWidgets('Serenity renders the workspace shell', (tester) async {
    await tester.pumpWidget(const SerenityApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Story Moodboard'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
    expect(find.text('2 images, 1 video'), findsOneWidget);
  });
}
