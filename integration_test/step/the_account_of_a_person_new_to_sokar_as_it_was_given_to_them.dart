import 'package:flutter_test/flutter_test.dart';

import '../support/new_person.dart';
import '../support/remote.dart';

/// Usage: the account of a person new to Sokar, as it was given to them
///
/// As it was made: Sokar installed on the machine and set up for the account, nothing of
/// Sokar's used yet - no daemon running, no vault, no project, no task, no connection. What an
/// earlier walk left is taken away first, the daemon stopped and its containers removed.
Future<void> theAccountOfAPersonNewToSokarAsItWasGivenToThem(WidgetTester tester) async {
  if (!walkingAsANewPerson) {
    markTestSkipped('the walk of a new person runs only with SOKAR_E2E_NEW_PERSON=1');
    return;
  }
  final left = await onTheTestMachine(r'''
set -u
systemctl --user stop sokard 2>/dev/null || true
podman rm -af >/dev/null 2>&1 || true
rm -rf "$HOME/.local/share/sokar" "$HOME/.config/sokar" "$HOME/.cache/sokar" "$HOME/work"
find "$HOME/.local/state/sokar" -mindepth 1 -maxdepth 1 ! -name default -exec rm -rf {} + 2>/dev/null || true
systemctl --user is-active sokard 2>/dev/null || true
ls -A "$HOME/.local/share" "$HOME/.local/state/sokar"
''');
  expect(left, isNot(contains('sokar\n')), reason: left);
}
