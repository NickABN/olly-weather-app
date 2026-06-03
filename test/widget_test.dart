import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WeatherApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsNothing);
    expect(find.byType(Router<Object>), findsOneWidget);
  });
}
