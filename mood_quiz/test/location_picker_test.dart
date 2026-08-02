import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/pages/location_picker_page.dart';

void main() {
  testWidgets('location picker searches and selects a nearby landmark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: LocationPickerPage(enableLiveLocation: false)),
    );
    await tester.pump();

    expect(find.text('My Location'), findsOneWidget);
    expect(find.text('Papa John’s'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.enterText(find.byKey(const Key('location-search')), 'SCOTMID');
    await tester.pump();
    final scotmidRow = find.descendant(
      of: find.byType(ListView),
      matching: find.text('SCOTMID'),
    );
    expect(scotmidRow, findsOneWidget);
    expect(find.text('Papa John’s'), findsNothing);

    await tester.tap(scotmidRow);
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
