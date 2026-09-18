// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_show_the_protected_store.dart';
import './step/it_lists_the_credential.dart';
import './step/it_says.dart';
import './step/nothing_was_done_to_the_store.dart';
import './step/two_running_tasks_still_hold_what_they_read.dart';
import './step/i_shut_the_store.dart';
import './step/the_store_was_already_shut.dart';
import './step/the_store_is_shut.dart';
import './step/it_does_not_list_any_credential.dart';
import './step/the_store_is_open_and_holds_nothing.dart';
import './step/i_read_to_the_bottom_of_the_store.dart';
import './step/reading_the_store_is_slow.dart';
import './step/i_ask_about_the_store_twice.dart';
import './step/the_newer_answer_is_the_one_on_screen.dart';

void main() {
  group('''Seeing and shutting the secret store, without showing a value''',
      () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

    testWidgets(
        '''what the store holds is visible without doing anything to it''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await itListsTheCredential(tester, 'a-provider');
      await itSays(tester, 'open — its contents can be read');
      await nothingWasDoneToTheStore(tester);
    });
    testWidgets('''a value is never shown, only that something is there''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'api-key · 108 characters');
    });
    testWidgets('''shutting it says what locking could not reach''',
        (tester) async {
      await bddSetUp(tester);
      await twoRunningTasksStillHoldWhatTheyRead(tester);
      await iShowTheProtectedStore(tester);
      await iShutTheStore(tester);
      await itSays(tester, 'The store is shut.');
      await itSays(
          tester, '2 running tasks still hold what they read at start');
    });
    testWidgets(
        '''a store that was already shut says so rather than claiming it did something''',
        (tester) async {
      await bddSetUp(tester);
      await theStoreWasAlreadyShut(tester);
      await iShowTheProtectedStore(tester);
      await iShutTheStore(tester);
      await itSays(tester, 'The store was already shut.');
    });
    testWidgets('''a shut store is not an empty one''', (tester) async {
      await bddSetUp(tester);
      await theStoreIsShut(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'That is not the same as it holding nothing');
      await itDoesNotListAnyCredential(tester);
    });
    testWidgets('''an open store holding nothing says that, as a state''',
        (tester) async {
      await bddSetUp(tester);
      await theStoreIsOpenAndHoldsNothing(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester,
          'It is open and holds nothing. That is a state, not a failure.');
    });
    testWidgets(
        '''opening it again is answered beside the button that shuts it''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'The store is unlocked where the machine is');
      await itSays(tester, 'holds an ssh connection to that machine already');
    });
    testWidgets('''the other three are said too, rather than left blank''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await iReadToTheBottomOfTheStore(tester);
      await itSays(tester, 'sokar vault passphrase`, at the machine');
      await itSays(tester, 'never reveals a stored value');
      await itSays(tester, 'no default');
    });
    testWidgets('''a slow answer never lands on top of a newer one''',
        (tester) async {
      await bddSetUp(tester);
      await readingTheStoreIsSlow(tester);
      await iAskAboutTheStoreTwice(tester);
      await theNewerAnswerIsTheOneOnScreen(tester);
    });
    testWidgets(
        '''where somebody looks for key routing, they are told there is none''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await iReadToTheBottomOfTheStore(tester);
      await itSays(tester, 'Nothing routes keys to projects, and nothing will');
      await itSays(tester, 'there is no link here to make or unmake');
    });
  });
}
