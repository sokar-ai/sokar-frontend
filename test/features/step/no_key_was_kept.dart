import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no key was kept
Future<void> noKeyWasKept(WidgetTester tester) async {
  final ssh = Directory('${World.setup.home.path}/.ssh');
  expect(ssh.existsSync() ? ssh.listSync() : const <FileSystemEntity>[], isEmpty);
}
