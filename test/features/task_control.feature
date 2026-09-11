# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Stopping, renaming and recreating work, and what that destroys

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    And I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}

  Scenario: work holding commits that never reached the gate is refused, not removed
    Given stopping will refuse because the work is held
    When I ask to stop the selected work
    And I confirm
    Then what is held is shown
    And the status line mentions {'holds work that never reached the gate'}
    When I choose {'Leave it alone'}
    Then the work {'sokar-checkout-shell'} is listed

  Scenario: what is held can be pushed to the mirror before it is removed
    Given stopping will refuse because the work is held
    When I ask to stop the selected work
    And I confirm
    And I choose {'Push what it holds to the mirror, then remove it'}
    Then the stop asked to rescue what was held

  Scenario: what is held is discarded only when that is chosen in those words
    Given stopping will refuse because the work is held
    When I ask to stop the selected work
    And I confirm
    And I choose {'Discard what it holds and remove it'}
    Then the stop asked to discard what was held

  Scenario: leaving a refusal alone touches nothing
    Given stopping will refuse because the work is held
    When I ask to stop the selected work
    And I confirm
    And I choose {'Leave it alone'}
    Then nothing more was asked of the backend
    And the work {'sokar-checkout-shell'} is listed
    And the status line mentions {'nothing was touched'}

  Scenario: work with nothing held is stopped, and stops being listed
    When I ask to stop the selected work
    And I confirm
    Then the status line mentions {'was stopped and removed'}
    And the status line mentions {'128 paths it had added went with it'}
    And the work {'sokar-checkout-shell'} is no longer listed

  Scenario: the confirmation names what is destroyed along with the work
    When I ask to stop the selected work
    Then the confirmation says {'exists nowhere else'}

  Scenario: an action the state does not allow is offered as unavailable, not hidden
    When I open the actions for {'sokar-checkout-shell'}
    Then the action {'Start it again'} is offered as unavailable

  Scenario: an action with no method behind it says so rather than going missing
    When I open the actions for {'sokar-checkout-shell'}
    Then the action {'Rename it'} is offered as unavailable

  Scenario: work carries a caption a person can change, beside its identity
    When I give this work something to read by {'schema migration, second attempt'}
    Then the work reads as {'schema migration, second attempt'}
    And its name is still shown as {'sokar-checkout-shell'}

  Scenario: the caption never becomes the identity
    When I give this work something to read by {'schema migration'}
    And I open the selection
    Then it says its name is {'sokar-checkout-shell'}

  Scenario: an empty caption takes it away rather than storing nothing
    Given this work already reads as {'schema migration'}
    When I give this work something to read by {''}
    Then the work reads as {'sokar-checkout-shell'}
    And the caption sent was empty

  Scenario: the dialog says the name will not move
    When I ask what this work should read as
    Then it says {'Its name stays sokar-checkout-shell'}

  Scenario: recreating says why it exists, and what it costs
    When I ask to recreate the selected work
    Then it says {'picks up a newly built environment'}
    And it says {'goes with it and exists nowhere else'}

  Scenario: recreating stops it and starts the same work again
    When I ask to recreate the selected work
    And I agree to recreate it
    Then the stop asked for {'sokar-checkout-shell'}
    And the launch was called {'sokar-checkout-shell'}

  Scenario: work that holds unpushed commits stops the recreation, and says so
    Given stopping will refuse because the work is held
    When I ask to recreate the selected work
    And I agree to recreate it
    Then what is held is shown
    And nothing was started
