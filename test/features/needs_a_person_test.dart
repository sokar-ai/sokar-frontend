// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/the_view_shown_is_what_needs_a_person.dart';
import './step/other_work_is_blocked_reaching.dart';
import './step/the_first_tile_is.dart';
import './step/work_is_blocked_reaching.dart';
import './step/the_tile_says.dart';
import './step/i_let_it_through_from_its_tile.dart';
import './step/the_answer_sent_was.dart';
import './step/the_work_is_idle.dart';
import './step/the_work_is_waiting_on.dart';
import './step/the_tile_is_marked_as_a_guess.dart';
import './step/the_tile_is_not_marked_as_a_guess.dart';
import './step/the_work_cannot_be_seen.dart';
import './step/i_watch_another_machine_called.dart';
import './step/the_tunnel_drops.dart';
import './step/a_tile_says.dart';
import './step/enough_time_passes_for_another_try.dart';
import './step/no_tile_says.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_is_open.dart';
import './step/the_machine_is_the_same_node.dart';
import './step/the_same_question_arrives_through_both.dart';
import './step/tile_asks_to_reach.dart';
import './step/i_work_in_by_hand_from_its_tile.dart';
import './step/the_session_runs.dart';
import './step/i_put_the_session_away.dart';
import './step/i_review_the_work_from_its_tile.dart';
import './step/i_open_the_waiting_push.dart';
import './step/the_review_shows_the_file.dart';
import './step/work_is_blocked_reaching_with_minutes_left.dart';
import './step/work_is_blocked_reaching_with_no_deadline.dart';
import './step/work_is_blocked_reaching_past_its_deadline.dart';
import './step/the_tile_does_not_say.dart';
import './step/other_work_is_blocked_reaching_with_minutes_left.dart';
import './step/the_name_on_the_tile_can_be_copied.dart';
import './step/i_open_the_menu_of_the_tile.dart';
import './step/the_menu_offers.dart';
import './step/i_click_the_tile_with_the_right_button.dart';
import './step/the_menu_offers_as_unavailable_because.dart';
import './step/i_choose_from_the_menu_of_the_tile.dart';
import './step/i_confirm.dart';
import './step/was_stopped_on_the_machine.dart';
import './step/nothing_was_stopped_on_this_machine.dart';
import './step/the_tile_is_headed.dart';
import './step/the_work_has_stopped.dart';
import './step/was_started_again.dart';
import './step/starting_it_again_finds_no_container.dart';

void main() {
  group('''What needs a person on every machine, without going anywhere''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets('''the window opens on what needs a person''', (tester) async {
      await bddSetUp(tester);
      await theViewShownIsWhatNeedsAPerson(tester);
    });
    testWidgets(
        '''a question waiting for an answer is above work that is merely running''',
        (tester) async {
      await bddSetUp(tester);
      await otherWorkIsBlockedReaching(tester, 'files.example.test:22');
      await theFirstTileIs(tester, 'sokar-billing-shell');
    });
    testWidgets(
        '''a question says how long it has been blocked, not a deadline nobody sent''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await theTileSays(tester, 'sokar-checkout-shell', 'blocked for');
      await theTileSays(tester, 'sokar-checkout-shell', 'does not say when');
    });
    testWidgets(
        '''a question is answered from its tile, without leaving the view''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iLetItThroughFromItsTile(tester);
      await theAnswerSentWas(tester, 'allow');
      await theViewShownIsWhatNeedsAPerson(tester);
    });
    testWidgets(
        '''a quiet task is marked as a guess, and a known state never is''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkIsIdle(tester, 'sokar-checkout-shell');
      await theWorkIsWaitingOn(
          tester, 'sokar-billing-shell', 'api.example.test:443');
      await theTileIsMarkedAsAGuess(tester, 'sokar-checkout-shell');
      await theTileIsNotMarkedAsAGuess(tester, 'sokar-billing-shell');
    });
    testWidgets('''work nothing can see is never drawn as quiet''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkCannotBeSeen(tester, 'sokar-checkout-shell');
      await theTileSays(tester, 'sokar-checkout-shell', 'Cannot be seen');
      await theTileIsNotMarkedAsAGuess(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''work on another machine is in the same list, with its machine on it''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await theTileSays(tester, 'sokar-shared-shell', 'elsewhere');
    });
    testWidgets(
        '''a machine that cannot be reached says so as a tile, not as an absence''',
        (tester) async {
      await bddSetUp(tester);
      await theTunnelDrops(tester);
      await aTileSays(tester, 'Cannot be reached');
      await enoughTimePassesForAnotherTry(tester);
      await noTileSays(tester, 'Cannot be reached');
    });
    testWidgets('''the keyboard works the moment the window opens''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheCommandFinder(tester);
      await theCommandFinderIsOpen(tester);
    });
    testWidgets('''one node reached two ways asks each question once''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineIsTheSameNode(tester, 'elsewhere');
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await theSameQuestionArrivesThroughBoth(tester);
      await tileAsksToReach(tester, 1, 'api.example.test');
    });
    testWidgets(
        '''work is opened by hand from its tile, and putting it away comes back here''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInByHandFromItsTile(tester, 'sokar-checkout-shell');
      await theSessionRuns(tester, 'sokar task attach sokar-checkout-shell');
      await iPutTheSessionAway(tester);
      await theViewShownIsWhatNeedsAPerson(tester);
    });
    testWidgets(
        '''work waiting at the gate is reviewed from its tile, over the view''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewTheWorkFromItsTile(tester, 'sokar-checkout-migrate');
      await iOpenTheWaitingPush(tester);
      await theReviewShowsTheFile(tester, 'lib/money.dart');
    });
    testWidgets('''a question with a deadline says how long is left''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReachingWithMinutesLeft(
          tester, 'api.example.test:443', 3);
      await theTileSays(tester, 'sokar-checkout-shell', '3 minutes left');
    });
    testWidgets(
        '''a question that never runs out says so, rather than counting down''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReachingWithNoDeadline(tester, 'api.example.test:443');
      await theTileSays(tester, 'sokar-checkout-shell', 'does not run out');
    });
    testWidgets(
        '''a question past its deadline says its time is up, not how long is left''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReachingPastItsDeadline(
          tester, 'api.example.test:443');
      await theTileSays(tester, 'sokar-checkout-shell', 'out of time');
      await theTileDoesNotSay(tester, 'sokar-checkout-shell', 'left');
    });
    testWidgets('''the question nearest its deadline comes first''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReachingWithMinutesLeft(
          tester, 'api.example.test:443', 2);
      await otherWorkIsBlockedReachingWithMinutesLeft(
          tester, 'files.example.test:22', 10);
      await theFirstTileIs(tester, 'sokar-checkout-shell');
    });
    testWidgets('''the name on a tile can be selected and copied''',
        (tester) async {
      await bddSetUp(tester);
      await theNameOnTheTileCanBeCopied(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''a tile offers what its work can be told to do, from its menu''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheMenuOfTheTile(tester, 'sokar-checkout-shell');
      await theMenuOffers(tester, 'Work in it by hand');
    });
    testWidgets('''clicking a tile with the right button opens the same menu''',
        (tester) async {
      await bddSetUp(tester);
      await iClickTheTileWithTheRightButton(tester, 'sokar-checkout-shell');
      await theMenuOffers(tester, 'Work in it by hand');
    });
    testWidgets(
        '''work reached through a forwarded socket offers no session, and says why''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await iOpenTheMenuOfTheTile(tester, 'sokar-shared-shell');
      await theMenuOffersAsUnavailableBecause(
          tester, 'Work in it by hand', 'forwarded');
    });
    testWidgets('''stopping from another machine's tile stops it there''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Stop it and remove it', 'sokar-shared-shell');
      await iConfirm(tester);
      await wasStoppedOnTheMachine(tester, 'sokar-shared-shell', 'elsewhere');
      await nothingWasStoppedOnThisMachine(tester);
    });
    testWidgets('''every tile is headed by the machine its work is on''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await theTileIsHeaded(tester, 'sokar-shared-shell', 'elsewhere');
      await theTileIsHeaded(tester, 'sokar-checkout-shell', 'this machine');
    });
    testWidgets(
        '''work started again from its tile says what came of it, on the tile''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Start it again', 'sokar-checkout-shell');
      await wasStartedAgain(tester, 'sokar-checkout-shell');
      await theTileSays(tester, 'sokar-checkout-shell', 'is running again');
    });
    testWidgets(
        '''a start the machine could not carry out says so on the tile''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await startingItAgainFindsNoContainer(tester);
      await iChooseFromTheMenuOfTheTile(
          tester, 'Start it again', 'sokar-checkout-shell');
      await theTileSays(tester, 'sokar-checkout-shell', 'no container');
    });
  });
}
