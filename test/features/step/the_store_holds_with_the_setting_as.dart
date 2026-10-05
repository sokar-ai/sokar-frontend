import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the store holds {'f56-api'} with the setting {'token_url'} as {'https://auth.example.com/token'}
Future<void> theStoreHoldsWithTheSettingAs(WidgetTester tester, String name, String setting, String value) async {
  World.backend.theStoreIs = VaultState.from(<String, dynamic>{
    'vault': '/home/somebody/.local/share/sokar/vault.bin',
    'exists': true,
    'credentials': <Map<String, dynamic>>[
      <String, dynamic>{
        'name': name,
        'type': '',
        'characters': 21,
        'settings': <String, dynamic>{setting: value},
      },
    ],
    'readable': true,
  });
}
