# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F21 Continuity And Updates

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: leaving says what carries on without the window
    When I select the project {'checkout'}
    And I ask to close it
    Then it says {'sokar-checkout-shell'} keeps running

  Scenario: a decision that nothing will be listening for is said before leaving
    When work is blocked reaching {'api.example.test:443'}
    And I ask to close it
    Then it says {'Nothing will be listening for them once this closes'}

  Scenario: staying changes nothing
    When I ask to close it
    And I stay
    Then the app is still open

  Scenario: reopening comes back to the same selection
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And the app is restarted
    Then the project {'checkout'} is selected
    And the work {'sokar-checkout-shell'} is still selected

  Scenario: reopening comes back to the same section
    When I show what this session has run
    And the app is restarted
    Then the section shown is {'This session'}

  Scenario: a newer build installed underneath says so, and changes nothing on its own
    When a newer build is installed underneath
    Then it says a newer build is installed
    And the app is still open
