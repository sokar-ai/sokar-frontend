// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_choose_the_command.dart';
import './step/i_close_what_is_open.dart';
import './step/i_select_the_project.dart';
import './step/the_work_is_listed.dart';
import './step/the_operation_is_still_running.dart';
import './step/the_operation_prints.dart';
import './step/the_operation_shows.dart';
import './step/is_nowhere_on_the_frame.dart';
import './step/i_show_what_this_session_has_run.dart';
import './step/i_open_the_last_operation.dart';
import './step/the_operation_finishes.dart';
import './step/the_record_shows.dart';
import './step/the_operation_fails.dart';
import './step/the_record_marks_it_as_failed.dart';

void main() {
  group('''F13 Operation Feedback And History''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets('''the frame stays usable while a long operation runs''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Check that work can start here, creating nothing');
      await iCloseWhatIsOpen(tester);
      await iSelectTheProject(tester, 'checkout');
      await theWorkIsListed(tester, 'sokar-checkout-shell');
      await theOperationIsStillRunning(tester);
    });
    testWidgets('''output goes to the operation and disturbs nothing else''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Check that work can start here, creating nothing');
      await theOperationPrints(tester, 'Building the image');
      await theOperationShows(tester, 'Building the image');
      await iCloseWhatIsOpen(tester);
      await isNowhereOnTheFrame(tester, 'Building the image');
    });
    testWidgets(
        '''an operation can be left and watched again without stopping it''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Check that work can start here, creating nothing');
      await theOperationPrints(tester, 'step one');
      await iCloseWhatIsOpen(tester);
      await theOperationPrints(tester, 'step two');
      await iShowWhatThisSessionHasRun(tester);
      await iOpenTheLastOperation(tester);
      await theOperationShows(tester, 'step one');
      await theOperationShows(tester, 'step two');
      await theOperationIsStillRunning(tester);
    });
    testWidgets(
        '''everything this session ran is listed afterwards with its outcome''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Check that work can start here, creating nothing');
      await theOperationFinishes(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'Check that work can start');
      await theRecordShows(tester, 'Finished.');
    });
    testWidgets(
        '''failure is reported where success would have been, with the output that explains it''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Check that work can start here, creating nothing');
      await theOperationPrints(tester, 'could not read project.yml');
      await theOperationFails(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'exit code 1');
      await theRecordMarksItAsFailed(tester);
      await iOpenTheLastOperation(tester);
      await theOperationShows(tester, 'could not read project.yml');
    });
  });
}
