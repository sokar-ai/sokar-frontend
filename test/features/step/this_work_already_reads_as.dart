import 'package:flutter_test/flutter_test.dart';

import 'i_give_this_work_something_to_read_by.dart';

/// Usage: this work already reads as {'schema migration'}
Future<void> thisWorkAlreadyReadsAs(WidgetTester tester, String caption) =>
    iGiveThisWorkSomethingToReadBy(tester, caption);
