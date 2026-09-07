import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/main.dart';

Future<void> theAppIsRunning(WidgetTester tester) async {
  await tester.pumpWidget(const SokarFrontendApp());
}
