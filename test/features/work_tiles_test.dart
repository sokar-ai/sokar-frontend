// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/the_work_is_idle.dart';
import './step/the_work_is_waiting_on.dart';
import './step/the_tile_is_marked_as_a_guess.dart';
import './step/the_tile_is_not_marked_as_a_guess.dart';
import './step/the_work_cannot_be_seen.dart';
import './step/the_tile_says.dart';
import './step/i_work_in_by_hand_from_its_tile.dart';
import './step/the_session_runs.dart';
import './step/i_put_the_session_away.dart';
import './step/the_view_shown_is_the_work.dart';
import './step/no_project_is_selected.dart';
import './step/i_select_the_project.dart';
import './step/the_project_is_selected.dart';
import './step/the_name_on_the_tile_can_be_copied.dart';
import './step/i_open_the_menu_of_the_tile.dart';
import './step/the_menu_offers.dart';
import './step/i_click_the_tile_with_the_right_button.dart';
import './step/the_work_has_stopped.dart';
import './step/i_choose_from_the_menu_of_the_tile.dart';
import './step/was_started_again.dart';
import './step/starting_it_again_will_be_refused_because_the_vault_is_locked.dart';
import './step/starting_it_again_will_fail_with_exit_code_saying.dart';
import './step/the_machine_says_starting_needs_the_vault_unlocked.dart';
import './step/the_menu_offers_as_unavailable_because.dart';
import './step/the_machine_says_was_started_before_the_machine_restarted.dart';
import './step/the_machine_says_has_a_name_from_before_one_container_per_task.dart';

void main() {
  group('''Work in its machine's area, as tiles that carry their own actions''',
      () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

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
        '''work is opened by hand from Running, and putting it away comes back to Running''',
        (tester) async {
      await bddSetUp(tester);
      await iWorkInByHandFromItsTile(tester, 'sokar-checkout-shell');
      await theSessionRuns(tester, 'sokar task attach sokar-checkout-shell');
      await iPutTheSessionAway(tester);
      await theViewShownIsTheWork(tester);
      await noProjectIsSelected(tester);
    });
    testWidgets(
        '''work opened by hand from its project comes back to that project''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iWorkInByHandFromItsTile(tester, 'sokar-checkout-shell');
      await iPutTheSessionAway(tester);
      await theViewShownIsTheWork(tester);
      await theProjectIsSelected(tester, 'checkout');
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
        '''work started again from its tile says what came of it, on the tile''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await iSelectTheProject(tester, 'checkout');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Start it again', 'sokar-checkout-shell');
      await wasStartedAgain(tester, 'sokar-checkout-shell');
      await theTileSays(tester, 'sokar-checkout-shell', 'is running again');
    });
    testWidgets(
        '''a start the machine refused when pressed says so on the tile''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await startingItAgainWillBeRefusedBecauseTheVaultIsLocked(tester);
      await iSelectTheProject(tester, 'checkout');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Start it again', 'sokar-checkout-shell');
      await theTileSays(tester, 'sokar-checkout-shell', 'the vault is locked');
    });
    testWidgets(
        '''a start that failed with an exit code says what the machine printed, on the tile''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await startingItAgainWillFailWithExitCodeSaying(
          tester, 70, 'Several agents are installed');
      await iSelectTheProject(tester, 'checkout');
      await iChooseFromTheMenuOfTheTile(
          tester, 'Start it again', 'sokar-checkout-shell');
      await theTileSays(
          tester, 'sokar-checkout-shell', 'Several agents are installed');
    });
    testWidgets(
        '''a start the machine would refuse is unavailable on the tile, with its reason''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await theMachineSaysStartingNeedsTheVaultUnlocked(
          tester, 'sokar-checkout-shell');
      await iSelectTheProject(tester, 'checkout');
      await iOpenTheMenuOfTheTile(tester, 'sokar-checkout-shell');
      await theMenuOffersAsUnavailableBecause(
          tester, 'Start it again', 'vault is locked');
    });
    testWidgets(
        '''work started before its machine restarted can only be recovered, and says how''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await theMachineSaysWasStartedBeforeTheMachineRestarted(
          tester, 'sokar-checkout-shell');
      await iSelectTheProject(tester, 'checkout');
      await iOpenTheMenuOfTheTile(tester, 'sokar-checkout-shell');
      await theMenuOffersAsUnavailableBecause(tester, 'Start it again',
          'podman cp sokar-checkout-shell:/workspace');
    });
    testWidgets(
        '''a container named from before one per task can only be removed''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasStopped(tester, 'sokar-checkout-shell');
      await theMachineSaysHasANameFromBeforeOneContainerPerTask(
          tester, 'sokar-checkout-shell');
      await iSelectTheProject(tester, 'checkout');
      await iOpenTheMenuOfTheTile(tester, 'sokar-checkout-shell');
      await theMenuOffersAsUnavailableBecause(
          tester, 'Start it again', 'can only be removed');
    });
  });
}
