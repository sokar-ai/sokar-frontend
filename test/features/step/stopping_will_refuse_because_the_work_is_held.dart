import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: stopping will refuse because the work is held
Future<void> stoppingWillRefuseBecauseTheWorkIsHeld(WidgetTester tester) async {
  // On demand, without contriving a task that genuinely holds commits — which is the whole
  // reason a refusal can be tested at all.
  World.backend.nextStop = Stopped.from(const <String, dynamic>{
    'outcome': 'HOLDS_WORK',
    'work': '2 commits on refs/heads/fix-rounding',
    'rescuedRef': '',
    'removed': false,
    'helpers': 0,
    'surviving': 2,
    'detail': '',
  });
}
