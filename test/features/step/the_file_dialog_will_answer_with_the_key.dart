import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the file dialog will answer with the key {'id_work'}
Future<void> theFileDialogWillAnswerWithTheKey(WidgetTester tester, String name) async {
  World.pickedFile = '${World.setup.home.path}/.ssh/$name';
}
