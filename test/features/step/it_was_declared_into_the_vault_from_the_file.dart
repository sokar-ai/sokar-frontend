import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was declared into the vault from the file {'/home/me/.ssh/id_ed25519'}
Future<void> itWasDeclaredIntoTheVaultFromTheFile(WidgetTester tester, String path) async {
  expect(World.backend.declared.single.source, 'VAULT');
  expect(World.backend.fromFiles.single, path);
}
