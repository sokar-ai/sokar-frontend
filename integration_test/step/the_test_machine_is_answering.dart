import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: the test machine is answering
Future<void> theTestMachineIsAnswering(WidgetTester tester) async {
  await switchTo(tester, E2e.name);
  await pumpUntil(
    tester,
    () => find.byTooltip('${E2e.name}: Answering').evaluate().isNotEmpty,
    timeout: const Duration(seconds: 45),
    what: '${E2e.name} answering',
  );
}
