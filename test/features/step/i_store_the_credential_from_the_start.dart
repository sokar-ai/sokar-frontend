import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I store the credential from the start
Future<void> iStoreTheCredentialFromTheStart(WidgetTester tester) async {
  askedBeforeStoring = World.backend.canStartAsked;
  await World.tapInView(tester, 'store-the-credential');
}

/// How often starting had been asked about when the credential was stored.
int askedBeforeStoring = 0;
