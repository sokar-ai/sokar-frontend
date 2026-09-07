import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/ui/panes.dart';

/// Usage: the app is still open
Future<void> theAppIsStillOpen(WidgetTester tester) async {
  // Declining leaves everything exactly as it was; nothing here closes or restarts on its own.
  expect(find.byType(ProjectsPane), findsOneWidget);
}
