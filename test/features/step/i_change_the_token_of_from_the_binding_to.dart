import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_change_to_be_called_with_the_token.dart';

/// Usage: I change the token of {'GitHub'} from the binding to {'ghp_admin'}
Future<void> iChangeTheTokenOfFromTheBindingTo(WidgetTester tester, String forge, String token) async {
  await World.tapInView(tester, 'binding-change-token');
  await iChangeToBeCalledWithTheToken(tester, forge, forge, token);
  await World.settle(tester);
}
