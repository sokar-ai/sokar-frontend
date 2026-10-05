import 'package:flutter_test/flutter_test.dart';

import 'i_look_at_the_forges_repository.dart';

/// Usage: I choose {'default-add'} from the card of {'acme/api'}
Future<void> iChooseFromTheCardOf(WidgetTester tester, String what, String repository) =>
    fromTheRepositorysMenu(tester, repository, what);
