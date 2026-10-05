import 'package:flutter_test/flutter_test.dart';

import '../support/new_person.dart';
import 'the_test_machine_has_a_repository_to_work_on.dart';

/// Usage: I have a repository {'my-first'} on that machine
///
/// One of the person's own, on the machine itself: the VM reaches no forge.
Future<void> iHaveARepositoryOnThatMachine(WidgetTester tester, String name) async {
  if (!walkingAsANewPerson) return;
  await theTestMachineHasARepositoryToWorkOn(tester, name);
}
