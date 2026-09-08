import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the store is shut
Future<void> theStoreIsShut(WidgetTester tester) async {
  // Shut and empty answer the same way about names, and must never be shown the same way.
  World.backend.theStoreIs = VaultState.from(const <String, dynamic>{
    'vault': '/home/somebody/.local/share/sokar/vault.bin',
    'exists': true,
    'credentials': <Map<String, dynamic>>[],
    'readable': false,
  });
}
