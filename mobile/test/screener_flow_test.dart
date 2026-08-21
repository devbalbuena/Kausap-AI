import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/screens/assessment/screener_flow_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('ScreenerFlowScreen renders phq9 and gad7 questions without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScreenerFlowScreen(screenerType: 'gad7'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GAD-7 Anxiety Screener'), findsOneWidget);
    expect(find.text('Question 1 of 7'), findsOneWidget);
    expect(find.text('Feeling nervous, anxious, or on edge?'), findsOneWidget);
    expect(find.text('Not at all'), findsOneWidget);
  });
}
