// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_show_what_has_been_backed_up_here.dart';
import './step/it_says.dart';
import './step/nothing_has_been_backed_up_here.dart';
import './step/i_consider_removing_the_first_backup.dart';
import './step/no_backup_was_removed.dart';
import './step/i_keep_the_backup.dart';
import './step/i_remove_the_backup.dart';
import './step/the_bundle_is_already_gone.dart';

void main() {
  group('''F06 Upstream Synchronisation And Backups''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets(
        '''what has been taken is listed with enough to tell two apart''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await itSays(tester, '/srv/checkout/backups/before-sync.bundle');
      await itSays(tester, '2 pushes when it was taken');
      await itSays(tester, '4.0 MB now');
    });
    testWidgets(
        '''a bundle somebody moved is shown as missing, never dropped''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await itSays(tester, '/srv/checkout/backups/moved-away.bundle');
      await itSays(tester, 'the file is not there any more');
    });
    testWidgets(
        '''a project with no record says so, without claiming no bundle exists''',
        (tester) async {
      await bddSetUp(tester);
      await nothingHasBeenBackedUpHere(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await itSays(tester, 'Nothing is recorded for this project');
      await itSays(tester, 'not the same as no bundle existing');
    });
    testWidgets('''removing one says what it held before anything goes''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await iConsiderRemovingTheFirstBackup(tester);
      await itSays(tester, 'It held 2 pushes nobody had reviewed');
      await noBackupWasRemoved(tester);
    });
    testWidgets('''keeping it removes nothing''', (tester) async {
      await bddSetUp(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await iConsiderRemovingTheFirstBackup(tester);
      await iKeepTheBackup(tester);
      await noBackupWasRemoved(tester);
    });
    testWidgets('''agreeing removes it, and says what it held''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await iConsiderRemovingTheFirstBackup(tester);
      await iRemoveTheBackup(tester);
      await itSays(tester, 'Gone: the bundle and the record of it');
    });
    testWidgets(
        '''clearing the record of a bundle already gone is not called a loss''',
        (tester) async {
      await bddSetUp(tester);
      await theBundleIsAlreadyGone(tester);
      await iShowWhatHasBeenBackedUpHere(tester);
      await iConsiderRemovingTheFirstBackup(tester);
      await iRemoveTheBackup(tester);
      await itSays(tester, 'The record is cleared. The file was already gone');
    });
  });
}
