import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the next change will be refused because the set is not installed
Future<void> theNextChangeWillBeRefusedBecauseTheSetIsNotInstalled(
    WidgetTester tester) async {
  // Every refusal is an outcome, not an exception.
  World.backend.nextChange = EgressChange.from(const <String, dynamic>{
    'outcome': 'NO_SUCH_SET',
    'opens': <Map<String, dynamic>>[],
    'closes': <Map<String, dynamic>>[],
    'cost': '',
    'detail': 'containers is not installed on this machine',
  });
}
