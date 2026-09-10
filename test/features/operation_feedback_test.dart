// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_choose_the_command.dart';
import './step/i_close_what_is_open.dart';
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
import './step/the_operation_runs_out_of_time.dart';
import './step/the_run_is_refused_before_it_begins.dart';

void main() {
  group('''Running long operations without blocking the frame''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets('''the frame stays usable while a long operation runs''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Show what this project would open, creating nothing');
      await iCloseWhatIsOpen(tester);
      await iSelectTheProject(tester, 'checkout');
      await theWorkIsListed(tester, 'sokar-checkout-shell');
      await theOperationIsStillRunning(tester);
    });
    testWidgets('''output goes to the operation and disturbs nothing else''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Show what this project would open, creating nothing');
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
          tester, 'Show what this project would open, creating nothing');
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
          tester, 'Show what this project would open, creating nothing');
      await theOperationFinishes(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'would open');
      await theRecordShows(tester, 'Finished.');
    });
    testWidgets(
        '''failure is reported where success would have been, with the output that explains it''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Show what this project would open, creating nothing');
      await theOperationPrints(tester, 'could not read project.yml');
      await theOperationFails(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'exited with code 1');
      await theRecordMarksItAsFailed(tester);
      await iOpenTheLastOperation(tester);
      await theOperationShows(tester, 'could not read project.yml');
    });
    testWidgets(
        '''a run stopped by its own time limit is not read as a run that went wrong''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Show what this project would open, creating nothing');
      await theOperationPrints(tester, 'agent: editing lib/money.dart');
      await theOperationRunsOutOfTime(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'ran out of the time it was given');
      await iOpenTheLastOperation(tester);
      await theOperationShows(tester, 'agent: editing lib/money.dart');
    });
    testWidgets(
        '''a run refused before it began says nothing was created, not that it failed''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(
          tester, 'Show what this project would open, creating nothing');
      await theRunIsRefusedBeforeItBegins(tester);
      await iCloseWhatIsOpen(tester);
      await iShowWhatThisSessionHasRun(tester);
      await theRecordShows(tester, 'Nothing ran, and nothing was created');
    });
  });
}
