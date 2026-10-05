import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the test machine has an ssh key of its own {'id_e2e'}
Future<void> theTestMachineHasAnSshKeyOfItsOwn(WidgetTester tester, String name) async {
  // Made there and never used to reach anything: a rented machine's account has no key at all.
  theKey = await onTheTestMachine('''
set -eu
mkdir -p -m 700 "\$HOME/.ssh"
[ -f "\$HOME/.ssh/$name" ] || ssh-keygen -q -t ed25519 -N "" -C "e2e@\$(hostname)" -f "\$HOME/.ssh/$name"
echo "\$HOME/.ssh/$name"
''');
}
