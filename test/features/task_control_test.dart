// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_select_the_work.dart';
import './step/stopping_will_refuse_because_the_work_is_held.dart';
import './step/i_ask_to_stop_the_selected_work.dart';
import './step/i_confirm.dart';
import './step/what_is_held_is_shown.dart';
import './step/the_status_line_mentions.dart';
import './step/i_choose.dart';
import './step/the_work_is_listed.dart';
import './step/the_stop_asked_to_rescue_what_was_held.dart';
import './step/the_stop_asked_to_discard_what_was_held.dart';
import './step/nothing_more_was_asked_of_the_backend.dart';
import './step/the_work_is_no_longer_listed.dart';
import './step/the_confirmation_says.dart';
import './step/i_open_the_actions_for.dart';
import './step/the_action_is_offered_as_unavailable.dart';

void main() {
  group('''F09 Task Control''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
    }

    testWidgets(
        '''work holding commits that never reached the gate is refused, not removed''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingWillRefuseBecauseTheWorkIsHeld(tester);
      await iAskToStopTheSelectedWork(tester);
      await iConfirm(tester);
      await whatIsHeldIsShown(tester);
      await theStatusLineMentions(
          tester, 'holds work that never reached the gate');
      await iChoose(tester, 'Leave it alone');
      await theWorkIsListed(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''what is held can be pushed to the mirror before it is removed''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingWillRefuseBecauseTheWorkIsHeld(tester);
      await iAskToStopTheSelectedWork(tester);
      await iConfirm(tester);
      await iChoose(tester, 'Push what it holds to the mirror, then remove it');
      await theStopAskedToRescueWhatWasHeld(tester);
    });
    testWidgets(
        '''what is held is discarded only when that is chosen in those words''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingWillRefuseBecauseTheWorkIsHeld(tester);
      await iAskToStopTheSelectedWork(tester);
      await iConfirm(tester);
      await iChoose(tester, 'Discard what it holds and remove it');
      await theStopAskedToDiscardWhatWasHeld(tester);
    });
    testWidgets('''leaving a refusal alone touches nothing''', (tester) async {
      await bddSetUp(tester);
      await stoppingWillRefuseBecauseTheWorkIsHeld(tester);
      await iAskToStopTheSelectedWork(tester);
      await iConfirm(tester);
      await iChoose(tester, 'Leave it alone');
      await nothingMoreWasAskedOfTheBackend(tester);
      await theWorkIsListed(tester, 'sokar-checkout-shell');
      await theStatusLineMentions(tester, 'nothing was touched');
    });
    testWidgets('''work with nothing held is stopped, and stops being listed''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopTheSelectedWork(tester);
      await iConfirm(tester);
      await theStatusLineMentions(tester, 'was stopped and removed');
      await theStatusLineMentions(
          tester, '128 paths it had added went with it');
      await theWorkIsNoLongerListed(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''the confirmation names what is destroyed along with the work''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopTheSelectedWork(tester);
      await theConfirmationSays(tester, 'exists nowhere else');
    });
    testWidgets(
        '''an action the state does not allow is offered as unavailable, not hidden''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheActionsFor(tester, 'sokar-checkout-shell');
      await theActionIsOfferedAsUnavailable(tester, 'Start it again');
    });
    testWidgets(
        '''an action with no method behind it says so rather than going missing''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheActionsFor(tester, 'sokar-checkout-shell');
      await theActionIsOfferedAsUnavailable(tester, 'Rename it');
    });
  });
}
