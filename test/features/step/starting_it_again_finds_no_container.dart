import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: starting it again finds no container
Future<void> startingItAgainFindsNoContainer(WidgetTester tester) async {
  World.backend.nextResume = Resumed.from(const <String, dynamic>{
    'outcome': 'NO_CONTAINER',
    'started': 0,
    'recorded': 0,
    'imageDrift': '',
    'problems': <String>[],
  });
}
