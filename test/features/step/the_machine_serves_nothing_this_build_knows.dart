import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine serves nothing this build knows
Future<void> theMachineServesNothingThisBuildKnows(WidgetTester tester) async {
  World.backend.whatItIs = const ServiceInfo(
    product: 'Sokar',
    version: '9.0.0',
    vendor: 'fuin.org',
    interfaces: <String>['org.varlink.service', 'org.fuin.sokar.Tasks2'],
  );
}
