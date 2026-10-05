import 'package:flutter_test/flutter_test.dart';

import 'the_project_names_no_credential_of_its_own.dart';

/// Usage: the project {'checkout'} names the credential {'a-provider'} for {'weather'}
Future<void> theProjectNamesTheCredentialFor(WidgetTester tester, String name, String entry, String destination) =>
    naming(tester, name, <String, String>{entry: destination});
