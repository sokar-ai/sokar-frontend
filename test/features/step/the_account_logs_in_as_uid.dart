import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the account logs in as uid {1000}
///
/// What `id -u` answers on that machine for the account the forward logs in as.
Future<void> theAccountLogsInAsUid(WidgetTester tester, int uid) async {
  World.loginUid = uid;
}
