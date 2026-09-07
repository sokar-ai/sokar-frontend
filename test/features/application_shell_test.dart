// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/the_project_is_listed.dart';
import './step/the_status_line_mentions.dart';
import './step/i_select_the_project.dart';
import './step/the_work_is_listed.dart';
import './step/i_select_the_work.dart';
import './step/i_open_the_selection.dart';
import './step/the_detail_for_is_shown.dart';
import './step/i_press_the_down_arrow.dart';
import './step/the_project_is_selected.dart';
import './step/i_close_the_detail.dart';
import './step/the_work_pane_is_shown.dart';
import './step/the_work_is_still_selected.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_names.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/i_choose_the_command.dart';
import './step/the_appearance_is.dart';
import './step/the_app_is_restarted.dart';
import './step/the_window_is_pixels_wide.dart';
import './step/the_work_pane_is_not_shown.dart';

void main() {
  group('''F01 Application Shell''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''what is on the machine is answered before anything is selected''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectIsListed(tester, 'checkout');
      await theProjectIsListed(tester, 'billing');
      await theStatusLineMentions(tester, 'Connected');
    });
    testWidgets('''a project and its work are each one selection away''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await theWorkIsListed(tester, 'sokar-checkout-shell');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await theDetailForIsShown(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''the frame is worked from the keyboard with no pointer at all''',
        (tester) async {
      await bddSetUp(tester);
      await iPressTheDownArrow(tester);
      await theProjectIsSelected(tester, 'billing');
      await iPressTheDownArrow(tester);
      await theProjectIsSelected(tester, 'checkout');
    });
    testWidgets(
        '''closing a detail comes back with the same selection still made''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await iCloseTheDetail(tester);
      await theWorkPaneIsShown(tester);
      await theWorkIsStillSelected(tester, 'sokar-checkout-shell');
      await theProjectIsSelected(tester, 'checkout');
    });
    testWidgets(
        '''one finder names actions belonging to a screen that is not open''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheCommandFinder(tester);
      await theCommandFinderNames(tester, 'Refresh from the backend');
      await theCommandFinderNames(tester, 'Open the selected work');
      await theCommandIsOfferedAsUnavailable(tester, 'Open the selected work');
    });
    testWidgets('''the status line says in words what the last action did''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Refresh from the backend');
      await theStatusLineMentions(tester, 'Refreshed');
    });
    testWidgets('''appearance is a choice and it survives a restart''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Appearance: dark');
      await theAppearanceIs(tester, 'dark');
      await theAppIsRestarted(tester);
      await theAppearanceIs(tester, 'dark');
    });
    testWidgets('''a window too narrow for two panes shows one at a time''',
        (tester) async {
      await bddSetUp(tester);
      await theWindowIsPixelsWide(tester, 360);
      await theProjectIsListed(tester, 'checkout');
      await theWorkPaneIsNotShown(tester);
    });
  });
}
