import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';
import 'work_on_the_test_machine_was_started_with_a_key_its_provider_refuses.dart';

/// Usage: the work its provider refused is removed again, with the key {'anthropic'}
Future<void> theWorkItsProviderRefusedIsRemovedAgainWithTheKey(WidgetTester tester, String entry) async {
  await onTheTestMachine('''
PATH="\$HOME/.local/bin:\$PATH"
sokar task remove --force $refusedTask >/dev/null 2>&1 || true
sokar project unfollow --force $refusedByItsProvider >/dev/null 2>&1 || true
rm -rf "\$HOME/$refusedByItsProvider"
sokar vault list | grep -q '^$entry ' && sokar vault remove --without-revoking $entry >/dev/null 2>&1 || true
''');
}
