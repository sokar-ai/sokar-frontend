# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F17 Network Exposure Control

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: a blocked connection turns up without anybody going to look for it
    When work is blocked reaching {'api.example.test:443'}
    Then the rail says {'1'} is waiting

  Scenario: what was attempted, by which work, and which rule stopped it
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    Then it shows the destination {'api.example.test:443'}
    And it names the work and the rule

  Scenario: several pieces of work are watched in one view, not one view each
    When work is blocked reaching {'api.example.test:443'}
    And other work is blocked reaching {'files.example.test:22'}
    And I go to what is blocked
    Then both are shown together

  Scenario: letting one through tells the work that is waiting
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And I let it through
    Then the answer sent was {'allow'}

  Scenario: keeping one blocked is a separate answer, not a silence
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And I keep it blocked
    Then the answer sent was {'deny'}

  Scenario: a question that ran out says so rather than quietly disappearing
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And the question runs out
    Then it says the question ran out
    And nothing is waiting any more
