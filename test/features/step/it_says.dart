import 'package:flutter_test/flutter_test.dart';

/// Usage: it says {'the attempt that was refused is gone'}
Future<void> itSays(WidgetTester tester, String words) async {
  expect(find.textContaining(words), findsWidgets);
}
