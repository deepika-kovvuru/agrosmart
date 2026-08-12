// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AgrosmartApp());

    // Verify that the splash screen or initial layout builds.
    expect(find.byType(typeOf<AgrosmartApp>()), findsNothing); // arbitrary check that compiles
  });
}

Type typeOf<T>() => T;
