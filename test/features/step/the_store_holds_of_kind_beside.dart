import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the store holds {'jira'} of kind {'oauth-device'} beside {'a-provider'}
Future<void> theStoreHoldsOfKindBeside(WidgetTester tester, String name, String kind, String other) async {
  World.backend.theStoreIs = VaultState.from(<String, dynamic>{
    'vault': '/home/somebody/.local/share/sokar/vault.bin',
    'exists': true,
    'credentials': <Map<String, dynamic>>[
      <String, dynamic>{'name': other, 'type': 'api-key', 'characters': 108},
      <String, dynamic>{
        'name': name,
        'type': kind,
        'characters': 0,
        'settings': <String, dynamic>{'client_id': 'sokar-test'},
      },
    ],
    'readable': true,
  });
}
