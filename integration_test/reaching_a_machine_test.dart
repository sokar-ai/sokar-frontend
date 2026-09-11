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
import './step/i_try_the_test_machine_from_the_dialog.dart';
import './step/the_trial_says.dart';
import './step/no_forward_raised_for_the_trial_is_left.dart';
import './step/i_put_the_dialog_away.dart';
import './step/i_try_the_test_machine_from_the_dialog_with_the_socket.dart';

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
    testWidgets('''a machine is tried from the dialog before it is watched''',
        (tester) async {
      await bddSetUp(tester);
      await iTryTheTestMachineFromTheDialog(tester);
      await theTrialSays(tester, 'Reached Sokar');
      await noForwardRaisedForTheTrialIsLeft(tester);
      await iPutTheDialogAway(tester);
    });
    testWidgets(
        '''a socket nobody serves on the test machine is found by trying it''',
        (tester) async {
      await bddSetUp(tester);
      await iTryTheTestMachineFromTheDialogWithTheSocket(
          tester, '/run/user/0/sokar/none.sock');
      await theTrialSays(tester,
          'nothing answers at /run/user/0/sokar/none.sock on that machine');
      await noForwardRaisedForTheTrialIsLeft(tester);
      await iPutTheDialogAway(tester);
    });
  });
}
