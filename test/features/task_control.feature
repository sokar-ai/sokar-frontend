# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F09 Task Control

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}

  Scenario: work holding commits that never reached the gate is refused, not removed
    Given stopping will refuse because the work is held
    When I stop the selected work
    Then what is held is shown
    And the status line mentions {'holds work that never reached the gate'}
    When I choose {'Leave it alone'}
    Then the work {'sokar-checkout-shell'} is listed

  Scenario: what is held can be pushed to the mirror before it is removed
    Given stopping will refuse because the work is held
    When I stop the selected work
    And I choose {'Push what it holds to the mirror, then remove it'}
    Then the stop asked to rescue what was held

  Scenario: what is held is discarded only when that is chosen in those words
    Given stopping will refuse because the work is held
    When I stop the selected work
    And I choose {'Discard what it holds and remove it'}
    Then the stop asked to discard what was held

  Scenario: leaving a refusal alone touches nothing
    Given stopping will refuse because the work is held
    When I stop the selected work
    And I choose {'Leave it alone'}
    Then nothing more was asked of the backend
    And the work {'sokar-checkout-shell'} is listed
    And the status line mentions {'nothing was touched'}

  Scenario: work with nothing held is stopped, and stops being listed
    When I stop the selected work
    Then the status line mentions {'was stopped and removed'}
    And the work {'sokar-checkout-shell'} is no longer listed

  Scenario: an action the state does not allow is offered as unavailable, not hidden
    When I open the actions for {'sokar-checkout-shell'}
    Then the action {'Start it again'} is offered as unavailable

  Scenario: an action with no method behind it says so rather than going missing
    When I open the actions for {'sokar-checkout-shell'}
    Then the action {'Rename it'} is offered as unavailable
