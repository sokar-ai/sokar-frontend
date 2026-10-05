import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_begin_revoking.dart';

/// Usage: I revoke {'old phone'}
Future<void> iRevoke(WidgetTester tester, String name) async {
  await iBeginRevoking(tester, name);
  await tester.tap(find.byKey(const Key('revoke-confirm')));
  await World.settle(tester);
}
