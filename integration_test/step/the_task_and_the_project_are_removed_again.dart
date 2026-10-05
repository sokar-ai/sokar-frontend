import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the task {'sokar-e2e-talk-e2e-talk'} and the project {'e2e-talk'} are removed again
Future<void> theTaskAndTheProjectAreRemovedAgain(WidgetTester tester, String task, String project) async {
  await onTheTestMachine('''
PATH="\$HOME/.local/bin:\$PATH"
sokar task stop "$task" >/dev/null 2>&1 || true
sokar task remove "$task" >/dev/null 2>&1 || true
sokar project unfollow --force "$project" >/dev/null 2>&1 || true
rm -rf "\$HOME/$project" "\$HOME/$project-backend.git"
''');
  final left = await onTheTestMachine('PATH="\$HOME/.local/bin:\$PATH"; sokar task list; sokar project list');
  expect(left, isNot(contains(task)));
}
