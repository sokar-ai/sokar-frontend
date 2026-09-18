# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Opening the store with an enrolled device, never with a passphrase

  # Against Sokar B60's proposal, which is not built yet: the fake answers the way the proposal
  # says a node does — a share it has seen opens its slot, nothing else does.
  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: enrolling keeps a key here and the machine lists this device
    When I show the protected store
    And I enroll this device as {'laptop'}
    Then it says {'This device can open the vault now, as "laptop".'}
    And it says {'laptop — this device'}
    And this device keeps the key the machine was given

  Scenario: before a device is enrolled, it says what its key is kept in
    When I show the protected store
    And I begin enrolling this device
    Then it says {'anything running as this user can read it'}

  Scenario: the key itself is never on screen
    When I show the protected store
    And I enroll this device as {'laptop'}
    Then the key this device keeps is nowhere on screen

  Scenario: a device that is not enrolled has nothing to open the store with
    When I show the protected store
    Then there is no way to open the store with this device

  # No default length: a bound that crept in would decide how often somebody is asked, and so would
  # its absence. Opening is refused until a length is chosen.
  Scenario: opening it asks how long, and chooses nothing for the person
    When I show the protected store
    And I enroll this device as {'laptop'}
    And I begin opening the store with this device
    Then it cannot be opened until a length is chosen

  Scenario: opening it for an hour asks the machine for sixty minutes
    When I show the protected store
    And I enroll this device as {'laptop'}
    And I open the store with this device {'for an hour'}
    Then the machine was asked to open it for {60} minutes
    And it says {'The vault is open until'}

  Scenario: opening it until it is shut asks for no bound
    When I show the protected store
    And I enroll this device as {'laptop'}
    And I open the store with this device {'until it is shut'}
    Then the machine was asked to open it without a bound

  Scenario: revoking another device keeps this one
    Given another device {'old phone'} can open the store
    When I show the protected store
    And I enroll this device as {'laptop'}
    And I revoke {'old phone'}
    Then it says {'"old phone" can no longer open the vault.'}
    And this device keeps the key the machine was given

  Scenario: revoking this device forgets its key here
    When I show the protected store
    And I enroll this device as {'laptop'}
    And I revoke {'laptop'}
    Then this device keeps no key for the machine
    And it offers to enroll this device

  # The way in when every device is gone. Revoking it from a window that may have lost its devices
  # is not offered; it is changed at the machine.
  Scenario: the recovery passphrase is listed and cannot be revoked from here
    When I show the protected store
    Then it says {'Used at the machine, with `sokar vault unlock`.'}
    And the recovery passphrase cannot be revoked from here

  Scenario: a machine whose Sokar predates devices says so rather than listing none
    Given the machine cannot enroll devices yet
    When I show the protected store
    Then it says {'that arrives with Sokar B60'}
    And it does not offer to enroll this device
