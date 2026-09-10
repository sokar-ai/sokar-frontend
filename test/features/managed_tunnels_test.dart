// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_start_watching_another_machine.dart';
import './step/i_choose.dart';
import './step/i_say_it_is_called.dart';
import './step/i_say_it_is_at.dart';
import './step/i_watch_it.dart';
import './step/the_forward_was_raised_for.dart';
import './step/the_machine_says_the_forward_is_raised_here.dart';
import './step/i_open_the_machine_dialog.dart';
import './step/watching_it_is_not_offered_yet.dart';
import './step/i_watch_another_machine_called.dart';
import './step/nothing_was_raised_for.dart';
import './step/the_machine_does_not_say_the_forward_is_raised_here.dart';
import './step/raising_a_forward_will_fail_with.dart';
import './step/the_machine_says.dart';
import './step/i_close_the_interface.dart';
import './step/no_forward_this_interface_raised_is_still_running.dart';
import './step/nothing_was_torn_down_for.dart';

void main() {
  group('''Raising and dropping the forward that reaches a machine''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''a machine is described by where it is, and the forward is raised here''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWatchingAnotherMachine(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iSayItIsCalled(tester, 'the build machine');
      await iSayItIsAt(tester, 'user@build.example.test');
      await iWatchIt(tester);
      await theForwardWasRaisedFor(tester, 'the build machine');
      await theMachineSaysTheForwardIsRaisedHere(tester, 'the build machine');
    });
    testWidgets('''how it is reached is chosen, never assumed''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheMachineDialog(tester);
      await iSayItIsCalled(tester, 'the build machine');
      await watchingItIsNotOfferedYet(tester);
    });
    testWidgets(
        '''a machine whose socket is already forwarded has nothing raised for it''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await nothingWasRaisedFor(tester, 'elsewhere');
      await theMachineDoesNotSayTheForwardIsRaisedHere(tester, 'elsewhere');
    });
    testWidgets(
        '''a forward that cannot be raised says what the transport said''',
        (tester) async {
      await bddSetUp(tester);
      await raisingAForwardWillFailWith(
          tester, 'Host key verification failed.');
      await iStartWatchingAnotherMachine(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iSayItIsCalled(tester, 'the build machine');
      await iSayItIsAt(tester, 'user@build.example.test');
      await iWatchIt(tester);
      await theMachineSays(
          tester, 'the build machine', 'Host key verification failed.');
    });
    testWidgets(
        '''closing the interface leaves no forward it raised still running''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWatchingAnotherMachine(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iSayItIsCalled(tester, 'the build machine');
      await iSayItIsAt(tester, 'user@build.example.test');
      await iWatchIt(tester);
      await iCloseTheInterface(tester);
      await noForwardThisInterfaceRaisedIsStillRunning(tester);
    });
    testWidgets(
        '''a forward the interface did not raise is never torn down by it''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await iCloseTheInterface(tester);
      await nothingWasTornDownFor(tester, 'elsewhere');
    });
  });
}
