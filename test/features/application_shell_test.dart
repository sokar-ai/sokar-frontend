// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/the_project_is_listed.dart';
import './step/the_status_line_mentions.dart';
import './step/i_select_the_project.dart';
import './step/the_work_is_listed.dart';
import './step/i_select_the_work.dart';
import './step/i_open_the_selection.dart';
import './step/the_detail_for_is_shown.dart';
import './step/i_move_the_keyboard_to_the_project.dart';
import './step/i_press_enter.dart';
import './step/the_project_is_selected.dart';
import './step/i_close_what_is_open.dart';
import './step/the_work_pane_is_shown.dart';
import './step/the_work_is_still_selected.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_names.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/i_open_the_menu.dart';
import './step/i_choose_the_menu_entry.dart';
import './step/the_appearance_is.dart';
import './step/i_choose_the_command.dart';
import './step/the_app_is_restarted.dart';
import './step/the_window_is_pixels_wide.dart';
import './step/i_pick_in_the_finder.dart';
import './step/the_menu_that_holds_is_open_with_it_marked.dart';
import './step/the_menu_bar_offers.dart';
import './step/the_work_is_no_longer_listed.dart';
import './step/i_show_what_is_running.dart';
import './step/the_work_is_dead.dart';
import './step/i_hide_the_projects_of.dart';
import './step/the_project_is_not_listed.dart';

void main() {
  group('''Moving around the frame by keyboard and by pointer''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
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
      await iMoveTheKeyboardToTheProject(tester, 'billing');
      await iPressEnter(tester);
      await theProjectIsSelected(tester, 'billing');
    });
    testWidgets(
        '''closing a detail comes back with the same selection still made''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await iCloseWhatIsOpen(tester);
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
    testWidgets('''every action is reachable with a pointer alone''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheMenu(tester, 'Options');
      await iChooseTheMenuEntry(tester, 'Appearance: dark');
      await theAppearanceIs(tester, 'dark');
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
    testWidgets('''a narrow window keeps the rail and the machine it is on''',
        (tester) async {
      await bddSetUp(tester);
      await theWindowIsPixelsWide(tester, 420);
      await theProjectIsListed(tester, 'checkout');
      await theWorkPaneIsShown(tester);
    });
    testWidgets(
        '''the finder goes to where an action lives and marks it there''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenTheCommandFinder(tester);
      await iPickInTheFinder(
          tester, 'Check whether this machine can run anything');
      await theMenuThatHoldsIsOpenWithItMarked(
          tester, 'Check whether this machine can run anything');
    });
    testWidgets('''the menu bar holds only what belongs to no machine''',
        (tester) async {
      await bddSetUp(tester);
      await theMenuBarOffers(tester, 'Machines, Options, About');
    });
    testWidgets(
        '''a project shows its own work, and Running shows what runs in every project''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await theWorkIsNoLongerListed(tester, 'sokar-billing-shell');
      await iShowWhatIsRunning(tester);
      await theWorkIsListed(tester, 'sokar-billing-shell');
    });
    testWidgets('''Running shows only the work that is running''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkIsDead(tester, 'sokar-checkout-shell');
      await iShowWhatIsRunning(tester);
      await theWorkIsNoLongerListed(tester, 'sokar-checkout-shell');
      await iSelectTheProject(tester, 'checkout');
      await theWorkIsListed(tester, 'sokar-checkout-shell');
    });
    testWidgets(
        '''a machine's projects can be hidden under it, and opening it shows them again''',
        (tester) async {
      await bddSetUp(tester);
      await iHideTheProjectsOf(tester, 'this machine');
      await theProjectIsNotListed(tester, 'checkout');
      await iGoToTheWork(tester);
      await theProjectIsListed(tester, 'checkout');
    });
  });
}
