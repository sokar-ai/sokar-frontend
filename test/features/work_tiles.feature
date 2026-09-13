# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Work in its machine's area, as tiles that carry their own actions

  # Work that needs nobody is not on what needs a person, so it is looked at where it lives.
  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: a quiet task is marked as a guess, and a known state never is
    Given the work {'sokar-checkout-shell'} is idle
    And the work {'sokar-billing-shell'} is waiting on {'api.example.test:443'}
    Then the tile {'sokar-checkout-shell'} is marked as a guess
    And the tile {'sokar-billing-shell'} is not marked as a guess

  Scenario: work nothing can see is never drawn as quiet
    Given the work {'sokar-checkout-shell'} cannot be seen
    Then the tile {'sokar-checkout-shell'} says {'Cannot be seen'}
    And the tile {'sokar-checkout-shell'} is not marked as a guess

  Scenario: work is opened by hand from its tile, and putting it away comes back to its machine
    When I work in {'sokar-checkout-shell'} by hand from its tile
    Then the session runs {'sokar task attach sokar-checkout-shell'}
    When I put the session away
    Then the view shown is the work

  Scenario: the name on a tile can be selected and copied
    Then the name on the tile {'sokar-checkout-shell'} can be copied

  Scenario: a tile offers what its work can be told to do, from its menu
    When I open the menu of the tile {'sokar-checkout-shell'}
    Then the menu offers {'Work in it by hand'}

  Scenario: clicking a tile with the right button opens the same menu
    When I click the tile {'sokar-checkout-shell'} with the right button
    Then the menu offers {'Work in it by hand'}

  # Stopped work is under its project, not under what is running.
  # The answer went only to the status line, and a start from a tile looked like nothing happened.
  Scenario: work started again from its tile says what came of it, on the tile
    Given the work {'sokar-checkout-shell'} has stopped
    When I select the project {'checkout'}
    And I choose {'Start it again'} from the menu of the tile {'sokar-checkout-shell'}
    Then {'sokar-checkout-shell'} was started again
    And the tile {'sokar-checkout-shell'} says {'is running again'}

  Scenario: a start the machine refused when pressed says so on the tile
    Given the work {'sokar-checkout-shell'} has stopped
    And starting it again will be refused because the vault is locked
    When I select the project {'checkout'}
    And I choose {'Start it again'} from the menu of the tile {'sokar-checkout-shell'}
    Then the tile {'sokar-checkout-shell'} says {'the vault is locked'}

  # The machine says beforehand what Start would do, so nobody finds a refusal by pressing.
  Scenario: a start the machine would refuse is unavailable on the tile, with its reason
    Given the work {'sokar-checkout-shell'} has stopped
    And the machine says starting {'sokar-checkout-shell'} needs the vault unlocked
    When I select the project {'checkout'}
    And I open the menu of the tile {'sokar-checkout-shell'}
    Then the menu offers {'Start it again'} as unavailable because {'vault is locked'}

  Scenario: a container named from before one per task can only be removed
    Given the work {'sokar-checkout-shell'} has stopped
    And the machine says {'sokar-checkout-shell'} has a name from before one container per task
    When I select the project {'checkout'}
    And I open the menu of the tile {'sokar-checkout-shell'}
    Then the menu offers {'Start it again'} as unavailable because {'can only be removed'}
