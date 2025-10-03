import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// IMPORTANT: this must match the "name:" in pubspec.yaml
import 'package:nyari/main.dart';

void main() {
  testWidgets('App builds without crashing', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    // If your app doesn’t render "Nyari" anywhere, change this to a text you always show.
    expect(find.textContaining('Nyari'), findsWidgets);
  });
}
