// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_select_the_work.dart';
import './step/i_work_in_it_by_hand.dart';
import './step/the_session_runs.dart';
import './step/i_start_watching_another_machine.dart';
import './step/i_choose.dart';
import './step/i_say_it_is_called.dart';
import './step/i_say_it_is_at.dart';
import './step/i_watch_it.dart';
import './step/i_switch_to_the_machine.dart';
import './step/the_session_prints.dart';
import './step/the_session_shows.dart';
import './step/i_type_into_the_session.dart';
import './step/the_session_was_sent.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/the_command_is_unavailable_because.dart';
import './step/the_work_is_dead.dart';
import './step/the_window_is_pixels_wide.dart';
import './step/the_session_is_on_screen.dart';
import './step/the_work_is_listed.dart';
import './step/the_work_pane_is_not_shown.dart';
import './step/i_put_the_session_away.dart';
import './step/the_work_is_still_selected.dart';
import './step/i_close_what_is_open.dart';
import './step/sessions_are_open.dart';
import './step/the_session_names.dart';
import './step/it_says.dart';
import './step/the_session_ends_with.dart';
import './step/the_work_was_never_stopped.dart';
import './step/i_leave_the_session.dart';
import './step/no_session_is_open.dart';

void main() {
  group('''F12 Interactive Session Attach''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'billing');
      await iSelectTheWork(tester, 'sokar-billing-shell');
    }

    testWidgets('''a session is one action from where the work is listed''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await theSessionRuns(tester, 'sokar task attach sokar-billing-shell');
    });
    testWidgets(
        '''a machine reached over ssh runs the same verb, through a terminal of its own''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWatchingAnotherMachine(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iSayItIsCalled(tester, 'the build machine');
      await iSayItIsAt(tester, 'user@build.example.test');
      await iWatchIt(tester);
      await iSwitchToTheMachine(tester, 'the build machine');
      await iSelectTheProject(tester, 'billing');
      await iSelectTheWork(tester, 'sokar-billing-shell');
      await iWorkInItByHand(tester);
      await theSessionRuns(tester,
          'ssh -t user@build.example.test sokar task attach sokar-billing-shell');
    });
    testWidgets('''what the far end prints is what is on the screen''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await theSessionPrints(tester, 'root@sokar-billing-shell:/work#');
      await theSessionShows(tester, 'root@sokar-billing-shell:/work#');
    });
    testWidgets('''what is typed reaches the far end''', (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iTypeIntoTheSession(tester, 'ls -l');
      await theSessionWasSent(tester, 'ls -l');
    });
    testWidgets(
        '''an offline project may be worked in by hand, though it may not be widened''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Let this work reach something new');
      await iWorkInItByHand(tester);
      await theSessionRuns(tester, 'sokar task attach sokar-billing-shell');
    });
    testWidgets(
        '''work an agent is driving has no session to join, and says so before it is pressed''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheCommandFinder(tester);
      await theCommandIsUnavailableBecause(
          tester, 'Work in it by hand', 'An agent is what runs in this');
    });
    testWidgets(
        '''work that has stopped has no session, and points at starting it again''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-billing-audit');
      await theWorkIsDead(tester, 'sokar-billing-audit');
      await iOpenTheCommandFinder(tester);
      await theCommandIsUnavailableBecause(tester, 'Work in it by hand',
          'Starting it again brings back the workspace');
    });
    testWidgets(
        '''on a wide window the work stays visible beside the session''',
        (tester) async {
      await bddSetUp(tester);
      await theWindowIsPixelsWide(tester, 1600);
      await iWorkInItByHand(tester);
      await theSessionIsOnScreen(tester);
      await theWorkIsListed(tester, 'sokar-billing-shell');
    });
    testWidgets(
        '''on a narrow window the session has the frame to itself, and leaving gives it back''',
        (tester) async {
      await bddSetUp(tester);
      await theWindowIsPixelsWide(tester, 700);
      await iWorkInItByHand(tester);
      await theSessionIsOnScreen(tester);
      await theWorkPaneIsNotShown(tester);
      await iPutTheSessionAway(tester);
      await theWorkIsStillSelected(tester, 'sokar-billing-shell');
    });
    testWidgets(
        '''leaving a session puts somebody back where they were, with the same work selected''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iPutTheSessionAway(tester);
      await theWorkIsStillSelected(tester, 'sokar-billing-shell');
    });
    testWidgets(
        '''Escape belongs to what is running, and never closes the session''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iCloseWhatIsOpen(tester);
      await theSessionIsOnScreen(tester);
      await sessionsAreOpen(tester, 1);
    });
    testWidgets(
        '''two sessions are open at once, and each says which work it is''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iPutTheSessionAway(tester);
      await iSelectTheWork(tester, 'sokar-billing-audit');
      await iWorkInItByHand(tester);
      await sessionsAreOpen(tester, 2);
      await theSessionNames(tester, 'sokar-billing-shell');
      await theSessionNames(tester, 'sokar-billing-audit');
    });
    testWidgets(
        '''asking for a session twice returns to the one that is already open''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iPutTheSessionAway(tester);
      await iWorkInItByHand(tester);
      await sessionsAreOpen(tester, 1);
    });
    testWidgets(
        '''the screen says that closing the window leaves the session running''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await itSays(tester, 'Closing this window leaves the session running');
    });
    testWidgets(
        '''a session the machine would not open says so, without claiming the work stopped''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await theSessionEndsWith(tester, 69);
      await itSays(tester, 'The machine would not open a session here');
      await theWorkWasNeverStopped(tester);
    });
    testWidgets(
        '''a connection that never happened is told apart from work that refused''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWatchingAnotherMachine(tester);
      await iChoose(tester, 'Raise the forward for me');
      await iSayItIsCalled(tester, 'the build machine');
      await iSayItIsAt(tester, 'user@build.example.test');
      await iWatchIt(tester);
      await iSwitchToTheMachine(tester, 'the build machine');
      await iSelectTheProject(tester, 'billing');
      await iSelectTheWork(tester, 'sokar-billing-shell');
      await iWorkInItByHand(tester);
      await theSessionEndsWith(tester, 255);
      await itSays(tester, 'The connection to the build machine failed');
    });
    testWidgets('''leaving a session closes the way in and stops nothing''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await iLeaveTheSession(tester);
      await noSessionIsOpen(tester);
      await theWorkWasNeverStopped(tester);
    });
    testWidgets(
        '''somebody who typed exit is not told that anything went wrong''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInItByHand(tester);
      await theSessionEndsWith(tester, 0);
      await itSays(
          tester, 'This way in is closed. The work is where you left it.');
    });
  });
}
