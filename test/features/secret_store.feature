# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Seeing and shutting the secret store, without showing a value

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: what the store holds is visible without doing anything to it
    When I show the protected store
    Then it lists the credential {'a-provider'}
    And it says {'open — its contents can be read'}
    And nothing was done to the store

  Scenario: a value is never shown, only that something is there
    When I show the protected store
    Then it says {'api-key · 108 characters'}

  Scenario: shutting it says what locking could not reach
    Given two running tasks still hold what they read
    When I show the protected store
    And I shut the store
    Then it says {'The store is shut.'}
    And it says {'2 running tasks still hold what they read at start'}

  Scenario: a store that was already shut says so rather than claiming it did something
    Given the store was already shut
    When I show the protected store
    And I shut the store
    Then it says {'The store was already shut.'}

  Scenario: a shut store is not an empty one
    Given the store is shut
    When I show the protected store
    Then it says {'That is not the same as it holding nothing'}
    And it does not list any credential

  Scenario: an open store holding nothing says that, as a state
    Given the store is open and holds nothing
    When I show the protected store
    Then it says {'It is open and holds nothing. That is a state, not a failure.'}

  # One line rather than a paragraph per thing: where each happens is all somebody needs.
  Scenario: what happens at the machine instead is said in one line
    When I show the protected store
    And I read to the bottom of the store
    Then it says {'`sokar vault unlock` opens it without a device'}
    And it says {'`sokar vault passphrase` changes its passphrase'}

  Scenario: a slow answer never lands on top of a newer one
    Given reading the store is slow
    When I ask about the store twice
    Then the newer answer is the one on screen
