# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: What needs a person on every machine, without going anywhere

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: the window opens on what needs a person
    Then the view shown is what needs a person

  Scenario: a question waiting for an answer is above work that is merely running
    When other work is blocked reaching {'files.example.test:22'}
    Then the first tile is {'sokar-billing-shell'}

  # Time remaining needs a deadline, and the machine does not send one yet.
  Scenario: a question says how long it has been blocked, not a deadline nobody sent
    When work is blocked reaching {'api.example.test:443'}
    Then the tile {'sokar-checkout-shell'} says {'blocked for'}
    And the tile {'sokar-checkout-shell'} says {'does not say when'}

  Scenario: a question is answered from its tile, without leaving the view
    When work is blocked reaching {'api.example.test:443'}
    And I let it through from its tile
    Then the answer sent was {'allow'}
    And the view shown is what needs a person

  Scenario: a quiet task is marked as a guess, and a known state never is
    Given the work {'sokar-checkout-shell'} is idle
    And the work {'sokar-billing-shell'} is waiting on {'api.example.test:443'}
    Then the tile {'sokar-checkout-shell'} is marked as a guess
    And the tile {'sokar-billing-shell'} is not marked as a guess

  Scenario: work nothing can see is never drawn as quiet
    Given the work {'sokar-checkout-shell'} cannot be seen
    Then the tile {'sokar-checkout-shell'} says {'Cannot be seen'}
    And the tile {'sokar-checkout-shell'} is not marked as a guess

  Scenario: work on another machine is in the same list, with its machine on it
    When I watch another machine called {'elsewhere'}
    Then the tile {'sokar-shared-shell'} says {'elsewhere'}

  Scenario: a machine that cannot be reached says so as a tile, not as an absence
    When the tunnel drops
    Then a tile says {'Cannot be reached'}
    When enough time passes for another try
    Then no tile says {'Cannot be reached'}

  Scenario: the keyboard works the moment the window opens
    When I open the command finder
    Then the command finder is open

  # The contract's own warning: the same node listed twice asks every question twice.
  Scenario: one node reached two ways asks each question once
    Given the machine {'elsewhere'} is the same node
    When I watch another machine called {'elsewhere'}
    And the same question arrives through both
    Then {1} tile asks to reach {'api.example.test'}

  Scenario: work is opened by hand from its tile, and putting it away comes back here
    When I work in {'sokar-checkout-shell'} by hand from its tile
    Then the session runs {'sokar task attach sokar-checkout-shell'}
    When I put the session away
    Then the view shown is what needs a person

  Scenario: work waiting at the gate is reviewed from its tile, over the view
    When I review the work {'sokar-checkout-migrate'} from its tile
    And I open the waiting push
    Then the review shows the file {'lib/money.dart'}

  Scenario: a question with a deadline says how long is left
    When work is blocked reaching {'api.example.test:443'} with {3} minutes left
    Then the tile {'sokar-checkout-shell'} says {'3 minutes left'}

  Scenario: a question that never runs out says so, rather than counting down
    When work is blocked reaching {'api.example.test:443'} with no deadline
    Then the tile {'sokar-checkout-shell'} says {'does not run out'}

  Scenario: a question past its deadline says its time is up, not how long is left
    When work is blocked reaching {'api.example.test:443'} past its deadline
    Then the tile {'sokar-checkout-shell'} says {'out of time'}
    And the tile {'sokar-checkout-shell'} does not say {'left'}

  # Alphabetical order would put billing first; only the deadline puts checkout there.
  Scenario: the question nearest its deadline comes first
    When work is blocked reaching {'api.example.test:443'} with {2} minutes left
    And other work is blocked reaching {'files.example.test:22'} with {10} minutes left
    Then the first tile is {'sokar-checkout-shell'}
