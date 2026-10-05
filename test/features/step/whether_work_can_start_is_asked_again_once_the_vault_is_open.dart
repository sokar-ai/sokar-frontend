import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_vault_from_the_start_with_this_device.dart';

/// Usage: whether work can start is asked again once the vault is open
Future<void> whetherWorkCanStartIsAskedAgainOnceTheVaultIsOpen(WidgetTester tester) async {
  expect(World.backend.canStartAsked, greaterThan(askedBeforeOpening));
}
