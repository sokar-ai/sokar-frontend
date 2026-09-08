import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: one helper will outlive the stop
Future<void> oneHelperWillOutliveTheStop(WidgetTester tester) async {
  World.backend.nextPanic = const Panicked(
    stopped: 3,
    surviving: <String>['sokar-checkout-shell-gate (pid 4711)'],
    previewed: false,
  );
}
