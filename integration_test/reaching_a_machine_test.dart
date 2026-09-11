// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import './step/the_interface_is_running.dart';
import './step/i_watch_the_test_machine_through_a_forward_raised_here.dart';
import './step/the_test_machine_is_answering.dart';
import './step/the_test_machine_is_being_watched.dart';
import './step/every_reply_it_gives_can_be_read.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('''Reaching a real machine and reading what its daemon says''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await theInterfaceIsRunning(tester);
    }

    testWidgets('''a machine added with a forward raised here is reached''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchTheTestMachineThroughAForwardRaisedHere(tester);
      await theTestMachineIsAnswering(tester);
    });
    testWidgets(
        '''every reply the interface reads can be read from the real daemon''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await everyReplyItGivesCanBeRead(tester);
    });
  });
}
