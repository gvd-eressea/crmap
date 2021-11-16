// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crmap_app/main.dart';

void main() {
  testWidgets('CR map smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    var myApp = MyApp();
    await tester.pumpWidget(myApp);

    // Verify that app starts with 'file open' tab.
    expect(find.byKey(Key('openCR')), findsOneWidget);


    // Tap the map tab and trigger a frame.
    await tester.tap(find.byKey(Key('map')));
    await tester.pumpAndSettle();

    // Verify that app switches tab.
    expect(find.byKey(Key('openCR')), findsNothing);
    // Verify that the map with at least one ocean field is shown.
    expect(find.byWidgetPredicate((widget) {
      return (widget is Text && widget.data.contains('Ozean / -1,8'));
    }),findsOneWidget);

    // Tap the ocean region and trigger a frame.
    await tester.tap(find.byWidgetPredicate((widget) {
      return (widget is Text && widget.data.contains('Ozean / -1,8'));
    }));
    await tester.pumpAndSettle();

    // Verify that app switches tab.
    expect(find.byKey(Key('openCR')), findsNothing);
    expect(find.byKey(Key('regionCard')), findsOneWidget);
  });
}
