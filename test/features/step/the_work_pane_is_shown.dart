import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/ui/panes.dart';

/// Usage: the work pane is shown
Future<void> theWorkPaneIsShown(WidgetTester tester) async {
  expect(find.byType(WorkPane), findsOneWidget);
}
