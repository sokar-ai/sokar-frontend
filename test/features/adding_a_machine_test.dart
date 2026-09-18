// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_open_the_machine_dialog.dart';
import './step/it_says.dart';
import './step/i_say_it_is_called.dart';
import './step/the_wizard_cannot_go_on_yet.dart';
import './step/i_choose.dart';
import './step/i_go_on.dart';
import './step/its_socket_there_is_not_filled_in.dart';
import './step/i_say_it_is_at.dart';
import './step/i_go_back.dart';
import './step/the_forwarded_socket_is.dart';
import './step/i_watch_it.dart';
import './step/nothing_was_raised_for.dart';

void main() {
  group('''Adding a machine through a wizard that starts from what you have''',
      () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
      await iOpenTheMachineDialog(tester);
    }

    testWidgets('''the first page asks for a name and one of three kinds''',
        (tester) async {
      await bddSetUp(tester);
      await itSays(tester, 'Its socket is already forwarded');
      await itSays(tester, 'Raise the forward for me');
      await itSays(tester, 'A new machine');
    });
    testWidgets('''the wizard goes on only with a name and a kind''',
        (tester) async {
      await bddSetUp(tester);
      await iSayItIsCalled(tester, 'the build machine');
      await theWizardCannotGoOnYet(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iGoOn(tester);
      await itsSocketThereIsNotFilledIn(tester);
    });
    testWidgets('''a kind without a name does not go on either''',
        (tester) async {
      await bddSetUp(tester);
      await iChoose(tester, 'Its socket is already forwarded');
      await theWizardCannotGoOnYet(tester);
    });
    testWidgets(
        '''going back keeps what was said, and another kind can be chosen''',
        (tester) async {
      await bddSetUp(tester);
      await iSayItIsCalled(tester, 'the build machine');
      await iChoose(tester, 'Raise the forward for me');
      await iGoOn(tester);
      await iSayItIsAt(tester, 'user@build.example.test');
      await iGoBack(tester);
      await iChoose(tester, 'Its socket is already forwarded');
      await iGoOn(tester);
      await theForwardedSocketIs(tester, '/tmp/sokar-build.sock');
      await iWatchIt(tester);
      await nothingWasRaisedFor(tester, 'the build machine');
    });
  });
}
