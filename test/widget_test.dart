import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App boots and mounts a router-driven MaterialApp',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WeatherApp()));
    // No pumpAndSettle: the auth redirect + network providers never settle
    // in a test harness. A single frame is enough to assert the shell mounts.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Router<Object>), findsOneWidget);
  });
}
