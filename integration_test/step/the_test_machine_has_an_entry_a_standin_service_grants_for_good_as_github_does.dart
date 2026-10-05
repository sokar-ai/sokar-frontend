import 'package:flutter_test/flutter_test.dart';

import 'the_test_machine_has_an_entry_a_standin_service_grants.dart';

/// Usage: the test machine has an entry {'e2e-lasting'} a stand-in service grants for good, as GitHub does
Future<void> theTestMachineHasAnEntryAStandinServiceGrantsForGoodAsGithubDoes(WidgetTester tester, String entry) =>
    anEntryAStandInGrants(entry, lasting: true);
