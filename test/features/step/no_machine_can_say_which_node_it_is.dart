import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no machine can say which node it is
///
/// A daemon older than the method. **Absence is not a value**: two machines that both say nothing
/// are not thereby the same one.
Future<void> noMachineCanSayWhichNodeItIs(WidgetTester tester) async {
  World.backend.nodeId = '';
  World.elsewhere.nodeId = '';
}
