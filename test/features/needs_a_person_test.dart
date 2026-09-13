// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/the_view_shown_is_what_needs_a_person.dart';
import './step/the_first_tile_is.dart';
import './step/no_tile_is_shown_for.dart';
import './step/other_work_is_blocked_reaching.dart';
import './step/work_is_blocked_reaching.dart';
import './step/the_tile_says.dart';
import './step/i_let_it_through_from_its_tile.dart';
import './step/the_answer_sent_was.dart';
import './step/the_answer_comes_back.dart';
import './step/i_put_away_what_the_tile_says.dart';
import './step/the_question_runs_out.dart';
import './step/i_watch_another_machine_called.dart';
import './step/work_on_is_blocked_reaching.dart';
import './step/the_tunnel_drops.dart';
import './step/a_machine_notice_says.dart';
import './step/no_tile_says.dart';
import './step/enough_time_passes_for_another_try.dart';
import './step/no_machine_notice_says.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_is_open.dart';
import './step/the_machine_is_the_same_node.dart';
import './step/the_same_question_arrives_through_both.dart';
import './step/tile_asks_to_reach.dart';
import './step/i_review_the_work_from_its_tile.dart';
import './step/i_open_the_waiting_push.dart';
import './step/the_review_shows_the_file.dart';
import './step/work_is_blocked_reaching_with_minutes_left.dart';
import './step/work_is_blocked_reaching_with_no_deadline.dart';
import './step/work_is_blocked_reaching_past_its_deadline.dart';
import './step/the_tile_does_not_say.dart';
import './step/other_work_is_blocked_reaching_with_minutes_left.dart';
import './step/i_open_the_menu_of_the_tile.dart';
import './step/the_menu_offers_as_unavailable_because.dart';
import './step/i_choose_from_the_menu_of_the_tile.dart';
import './step/was_stopped_on_the_machine.dart';
import './step/nothing_was_stopped_on_this_machine.dart';
import './step/the_tile_is_headed.dart';
import './step/i_mark_the_notice_about_as_seen.dart';
import './step/nothing_needs_me.dart';

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
    testWidgets('''work that needs nobody is not on what needs a person''',
        (tester) async {
      await bddSetUp(tester);
      await theFirstTileIs(tester, 'sokar-checkout-migrate');
      await noTileIsShownFor(tester, 'sokar-billing-shell');
      await noTileIsShownFor(tester, 'sokar-checkout-shell');
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
        '''a question let through stays with its answer until it is put away''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iLetItThroughFromItsTile(tester);
      await theAnswerComesBack(tester);
      await theTileSays(tester, 'sokar-checkout-shell', 'is now reachable');
      await iPutAwayWhatTheTileSays(tester, 'sokar-checkout-shell');
      await noTileIsShownFor(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''a question that ran out stays, saying so, until it is put away''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await theQuestionRunsOut(tester);
      await theTileSays(tester, 'sokar-checkout-shell', 'ran out');
      await iPutAwayWhatTheTileSays(tester, 'sokar-checkout-shell');
      await noTileIsShownFor(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''a question on another machine is in the same list, with its machine on it''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await workOnIsBlockedReaching(
          tester, 'elsewhere', 'api.example.test:443');
      await theTileSays(tester, 'sokar-shared-shell', 'elsewhere');
    });
    testWidgets(
        '''a machine that cannot be reached says so above the tiles, not as one''',
        (tester) async {
      await bddSetUp(tester);
      await theTunnelDrops(tester);
      await aMachineNoticeSays(tester, 'cannot be reached');
      await noTileSays(tester, 'cannot be reached');
      await enoughTimePassesForAnotherTry(tester);
      await noMachineNoticeSays(tester, 'cannot be reached');
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
    testWidgets(
        '''work reached through a forwarded socket offers no session, and says why''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await workOnIsBlockedReaching(
          tester, 'elsewhere', 'api.example.test:443');
      await iOpenTheMenuOfTheTile(tester, 'sokar-shared-shell');
      await theMenuOffersAsUnavailableBecause(
          tester, 'Work in it by hand', 'forwarded');
    });
    testWidgets('''stopping from another machine's tile stops it there''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await workOnIsBlockedReaching(
          tester, 'elsewhere', 'api.example.test:443');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Stop it, keeping its workspace', 'sokar-shared-shell');
      await wasStoppedOnTheMachine(tester, 'sokar-shared-shell', 'elsewhere');
      await nothingWasStoppedOnThisMachine(tester);
    });
    testWidgets('''every tile is headed by the machine its work is on''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchAnotherMachineCalled(tester, 'elsewhere');
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await workOnIsBlockedReaching(
          tester, 'elsewhere', 'files.example.test:22');
      await theTileIsHeaded(tester, 'sokar-shared-shell', 'elsewhere');
      await theTileIsHeaded(tester, 'sokar-checkout-shell', 'this machine');
    });
    testWidgets(
        '''a silent machine can be marked as seen, until it has answered again''',
        (tester) async {
      await bddSetUp(tester);
      await theTunnelDrops(tester);
      await iMarkTheNoticeAboutAsSeen(tester, 'this machine');
      await noMachineNoticeSays(tester, 'cannot be reached');
      await nothingNeedsMe(tester);
      await enoughTimePassesForAnotherTry(tester);
      await theTunnelDrops(tester);
      await aMachineNoticeSays(tester, 'cannot be reached');
      await enoughTimePassesForAnotherTry(tester);
      await noMachineNoticeSays(tester, 'cannot be reached');
    });
  });
}
