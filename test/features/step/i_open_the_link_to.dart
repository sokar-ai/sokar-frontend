import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the link to {'https://claude.com/cai/oauth/authorize?code=true'}
Future<void> iOpenTheLinkTo(WidgetTester tester, String address) async {
  await World.tapInView(tester, 'terminal-link $address');
}
