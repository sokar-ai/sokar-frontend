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
  });
}
