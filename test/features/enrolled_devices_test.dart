// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/enrolling_says.dart';
import './step/the_stores_lock_says.dart';
import './step/i_enroll_this_device_as.dart';
import './step/it_says.dart';
import './step/i_close_the_answer.dart';
import './step/i_show_the_protected_store.dart';
import './step/this_device_keeps_the_key_the_machine_was_given.dart';
import './step/enrolling_is_not_offered.dart';
import './step/i_begin_enrolling_this_device.dart';
import './step/the_key_this_device_keeps_is_nowhere_on_screen.dart';
import './step/the_store_is_shut.dart';
import './step/the_stores_lock_does_nothing.dart';
import './step/i_shut_the_store.dart';
import './step/i_begin_opening_the_store_with_this_device.dart';
import './step/it_cannot_be_opened_until_a_length_is_chosen.dart';
import './step/i_open_the_store_with_this_device.dart';
import './step/the_machine_was_asked_to_open_it_for_minutes.dart';
import './step/the_machine_was_asked_to_open_it_without_a_bound.dart';
import './step/another_device_can_open_the_store.dart';
import './step/i_revoke.dart';
import './step/this_device_keeps_no_key_for_the_machine.dart';
import './step/the_recovery_passphrase_cannot_be_revoked_from_here.dart';
import './step/the_machine_cannot_enroll_devices_yet.dart';
import './step/i_shut_the_store_from_the_machines_menu.dart';

void main() {
  group(
      '''Opening the store with an enrolled device, never with a passphrase''',
      () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

    testWidgets(
        '''a device that is not enrolled is offered enrolling, beside the lock''',
        (tester) async {
      await bddSetUp(tester);
      await enrollingSays(tester,
          'This device cannot open the store yet. Enroll it so it can.');
      await theStoresLockSays(tester, 'The store is open. Shut it.');
    });
    testWidgets(
        '''enrolling keeps a key here and the machine lists this device''',
        (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await itSays(tester, 'This device can open the vault now, as "laptop".');
      await iCloseTheAnswer(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'laptop — this device');
      await thisDeviceKeepsTheKeyTheMachineWasGiven(tester);
      await enrollingIsNotOffered(tester);
    });
    testWidgets(
        '''before a device is enrolled, it says what its key is kept in''',
        (tester) async {
      await bddSetUp(tester);
      await iBeginEnrollingThisDevice(tester);
      await itSays(tester, 'anything running as this user can read it');
    });
    testWidgets('''the key itself is never on screen''', (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShowTheProtectedStore(tester);
      await theKeyThisDeviceKeepsIsNowhereOnScreen(tester);
    });
    testWidgets(
        '''a shut store and a device that is not enrolled say where it is opened instead''',
        (tester) async {
      await bddSetUp(tester);
      await theStoreIsShut(tester);
      await theStoresLockSays(tester,
          'The store is shut, and this device is not enrolled. Unlock it at the machine with `sokar vault unlock`, then enroll this device.');
      await theStoresLockDoesNothing(tester);
      await enrollingSays(tester,
          'Enrolling needs the store open. Unlock it at the machine with `sokar vault unlock` first.');
    });
    testWidgets(
        '''opening it asks how long, and chooses nothing for the person''',
        (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShutTheStore(tester);
      await iCloseTheAnswer(tester);
      await iBeginOpeningTheStoreWithThisDevice(tester);
      await itCannotBeOpenedUntilALengthIsChosen(tester);
    });
    testWidgets(
        '''opening it for an hour asks the machine for sixty minutes, and it is open''',
        (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShutTheStore(tester);
      await iCloseTheAnswer(tester);
      await iOpenTheStoreWithThisDevice(tester, 'for an hour');
      await theMachineWasAskedToOpenItForMinutes(tester, 60);
      await itSays(tester, 'The vault is open until');
      await iCloseTheAnswer(tester);
      await theStoresLockSays(tester, 'The store is open. Shut it.');
    });
    testWidgets('''opening it until it is shut asks for no bound''',
        (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShutTheStore(tester);
      await iCloseTheAnswer(tester);
      await iOpenTheStoreWithThisDevice(tester, 'until it is shut');
      await theMachineWasAskedToOpenItWithoutABound(tester);
    });
    testWidgets('''revoking another device keeps this one''', (tester) async {
      await bddSetUp(tester);
      await anotherDeviceCanOpenTheStore(tester, 'old phone');
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShowTheProtectedStore(tester);
      await iRevoke(tester, 'old phone');
      await itSays(tester, '"old phone" can no longer open the vault.');
      await thisDeviceKeepsTheKeyTheMachineWasGiven(tester);
    });
    testWidgets(
        '''revoking this device forgets its key here, and enrolling is offered again''',
        (tester) async {
      await bddSetUp(tester);
      await iEnrollThisDeviceAs(tester, 'laptop');
      await iCloseTheAnswer(tester);
      await iShowTheProtectedStore(tester);
      await iRevoke(tester, 'laptop');
      await thisDeviceKeepsNoKeyForTheMachine(tester);
      await enrollingSays(tester,
          'This device cannot open the store yet. Enroll it so it can.');
    });
    testWidgets(
        '''the recovery passphrase is listed and cannot be revoked from here''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'The passphrase, used at the machine.');
      await theRecoveryPassphraseCannotBeRevokedFromHere(tester);
    });
    testWidgets(
        '''a machine whose Sokar predates devices has the lock, and says why not enrolling''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineCannotEnrollDevicesYet(tester);
      await theStoresLockSays(tester, 'The store is open. Shut it.');
      await enrollingIsNotOffered(tester);
      await iShowTheProtectedStore(tester);
      await itSays(tester, 'that arrives with Sokar B60');
    });
    testWidgets('''the machine's menu shuts the store too''', (tester) async {
      await bddSetUp(tester);
      await iShutTheStoreFromTheMachinesMenu(tester);
      await itSays(tester, 'The store is shut.');
      await iCloseTheAnswer(tester);
      await theStoresLockSays(tester,
          'The store is shut, and this device is not enrolled. Unlock it at the machine with `sokar vault unlock`, then enroll this device.');
    });
  });
}
