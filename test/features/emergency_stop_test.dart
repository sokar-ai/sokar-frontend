// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/stopping_everything_is_offered_on_the_frame.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_names.dart';
import './step/i_ask_to_stop_everything.dart';
import './step/nothing_has_been_stopped.dart';
import './step/it_says.dart';
import './step/leaving_it_running_is_the_default.dart';
import './step/i_agree_to_stop_everything.dart';
import './step/it_says_how_to_get_back_to_work.dart';
import './step/one_helper_will_outlive_the_stop.dart';
import './step/it_names_the_helper.dart';
import './step/the_backend_will_refuse_to_stop_everything.dart';
import './step/it_names_the_work_among_what_was_stopped.dart';
import './step/it_does_not_claim_everything_will_stop_cleanly.dart';

void main() {
  group('''F18 Emergency Stop''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''the way to stop everything is on screen without opening anything''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingEverythingIsOfferedOnTheFrame(tester);
    });
    testWidgets('''it is reachable by name as well''', (tester) async {
      await bddSetUp(tester);
      await iOpenTheCommandFinder(tester);
      await theCommandFinderNames(tester, 'Stop everything on this machine');
    });
    testWidgets('''it never stops anything on the first press''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await nothingHasBeenStopped(tester);
      await itSays(
          tester, 'This would stop the 3 pieces of work that are running');
    });
    testWidgets('''leaving is the default, so a stray Return carries nothing''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await leavingItRunningIsTheDefault(tester);
    });
    testWidgets(
        '''agreeing stops everything and says what state the machine is in''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await iAgreeToStopEverything(tester);
      await itSays(
          tester, 'Stopped the 3 that were running. Nothing was removed.');
      await itSays(tester, 'exactly where it was');
    });
    testWidgets('''the way back is named, not left to be worked out''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await iAgreeToStopEverything(tester);
      await itSaysHowToGetBackToWork(tester);
    });
    testWidgets('''a helper that outlived its stop is named, never counted''',
        (tester) async {
      await bddSetUp(tester);
      await oneHelperWillOutliveTheStop(tester);
      await iAskToStopEverything(tester);
      await iAgreeToStopEverything(tester);
      await itNamesTheHelper(tester, 'sokar-checkout-shell-gate (pid 4711)');
      await itSays(tester, 'killed on the machine by hand');
    });
    testWidgets('''losing the machine mid-stop says nothing was stopped''',
        (tester) async {
      await bddSetUp(tester);
      await theBackendWillRefuseToStopEverything(tester);
      await iAskToStopEverything(tester);
      await iAgreeToStopEverything(tester);
      await itSays(tester, 'Nothing was stopped, and work is still running');
    });
    testWidgets(
        '''what was stopped is named, because the name is how it comes back''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await iAgreeToStopEverything(tester);
      await itNamesTheWorkAmongWhatWasStopped(tester, 'sokar-checkout-shell');
    });
    testWidgets('''a preview promises nothing about what will survive''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopEverything(tester);
      await itDoesNotClaimEverythingWillStopCleanly(tester);
    });
  });
}
