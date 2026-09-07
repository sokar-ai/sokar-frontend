import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the next change will report a cost
Future<void> theNextChangeWillReportACost(WidgetTester tester) async {
  // Usually empty, and it matters when it is not: filled only when *this* change makes a forge
  // reachable for a guarded project, and never repeated later.
  World.backend.nextChange = EgressChange.from(const <String, dynamic>{
    'outcome': 'PREVIEWED',
    'opens': <Map<String, dynamic>>[
      <String, dynamic>{'host': 'github.com', 'origin': 'set containers'},
    ],
    'closes': <Map<String, dynamic>>[],
    'cost': 'the gate now rests on the container holding no credential rather '
        'than on the host being unreachable',
    'detail': '',
  });
}
