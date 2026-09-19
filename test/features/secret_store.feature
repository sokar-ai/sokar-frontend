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

  # A device can only be enrolled into an open store, so the first opening is always by the
  # passphrase — typed into a terminal on the machine, never into this program.
  Scenario: a shut store is opened by its passphrase in a terminal on the machine, then asked again
    Given the store is shut
    And the machine is reached over ssh as {'michi@vm'}
    When I show the protected store
    And I open it here with its passphrase
    Then a terminal runs {'ssh -t michi@vm sokar vault unlock'} on the machine
    And it says {'Nothing is shown in the terminal while a secret is typed'}
    When the unlock terminal ends and is put away
    Then the machine is asked again whether the store is open

  Scenario: a shut store on a device that is not enrolled is opened from the lock by its passphrase
    Given the store is shut
    And the machine is reached over ssh as {'michi@vm'}
    When I open the store with its passphrase from the lock
    Then a terminal runs {'ssh -t michi@vm sokar vault unlock'} on the machine

  # A socket somebody else forwarded has no host behind it; a sokar run here would open another vault.
  Scenario: a machine whose socket somebody else forwards is not offered a terminal to open it
    Given the store is shut
    And the machine is a socket somebody else forwards
    When I open the command finder
    Then the command {'Open the protected store with its passphrase, in a terminal'} is unavailable because {'forwarded by somebody else'}

  Scenario: this machine's own daemon is opened by its own sokar, here
    Given the store is shut
    When I show the protected store
    And I open it here with its passphrase
    Then a terminal runs {'sokar vault unlock'} on the machine

