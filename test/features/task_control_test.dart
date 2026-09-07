// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_app_is_running.dart';
import './step/the_placeholder_is_shown.dart';

void main() {
  group('''F09 Task Control''', () {
    testWidgets(
        '''a task holding unpushed work is refused rather than removed''',
        (tester) async {
      await theAppIsRunning(tester);
      await thePlaceholderIsShown(tester);
    });
  });
}
