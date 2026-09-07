# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F01 Application Shell

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: what is on the machine is answered before anything is selected
    Then the project {'checkout'} is listed
    And the project {'billing'} is listed
    And the status line mentions {'Connected'}

  Scenario: a project and its work are each one selection away
    When I select the project {'checkout'}
    Then the work {'sokar-checkout-shell'} is listed
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then the detail for {'sokar-checkout-shell'} is shown

  Scenario: the frame is worked from the keyboard with no pointer at all
    When I press the down arrow
    Then the project {'billing'} is selected
    When I press the down arrow
    Then the project {'checkout'} is selected

  Scenario: closing a detail comes back with the same selection still made
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I open the selection
    And I close what is open
    Then the work pane is shown
    And the work {'sokar-checkout-shell'} is still selected
    And the project {'checkout'} is selected

  Scenario: one finder names actions belonging to a screen that is not open
    When I open the command finder
    Then the command finder names {'Refresh from the backend'}
    And the command finder names {'Open the selected work'}
    And the command {'Open the selected work'} is offered as unavailable

  Scenario: the status line says in words what the last action did
    When I choose the command {'Refresh from the backend'}
    Then the status line mentions {'Refreshed'}

  Scenario: appearance is a choice and it survives a restart
    When I choose the command {'Appearance: dark'}
    Then the appearance is {'dark'}
    When the app is restarted
    Then the appearance is {'dark'}

  Scenario: a window too narrow for two panes shows one at a time
    When the window is {360} pixels wide
    Then the project {'checkout'} is listed
    And the work pane is not shown
