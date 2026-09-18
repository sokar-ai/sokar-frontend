# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Opening the store with an enrolled device, never with a passphrase

  # Against Sokar B60's proposal, which is not built yet: the fake answers the way the proposal
  # says a node does — a share it has seen opens its slot, nothing else does.
  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: a device that is not enrolled is offered enrolling, beside the lock
    Then enrolling says {'This device cannot open the store yet. Enroll it so it can.'}
    And the store's lock says {'The store is open. Shut it.'}

  Scenario: enrolling keeps a key here and the machine lists this device
    When I enroll this device as {'laptop'}
    Then it says {'This device can open the vault now, as "laptop".'}
    When I close the answer
    And I show the protected store
    Then it says {'laptop — this device'}
    And this device keeps the key the machine was given
    And enrolling is not offered

  Scenario: before a device is enrolled, it says what its key is kept in
    When I begin enrolling this device
    Then it says {'anything running as this user can read it'}

  Scenario: the key itself is never on screen
    When I enroll this device as {'laptop'}
    And I close the answer
    And I show the protected store
    Then the key this device keeps is nowhere on screen

  Scenario: a shut store and a device that is not enrolled say where it is opened instead
    Given the store is shut
    Then the store's lock says {'The store is shut, and this device is not enrolled. Unlock it at the machine with `sokar vault unlock`, then enroll this device.'}
    And the store's lock does nothing
    And enrolling says {'Enrolling needs the store open. Unlock it at the machine with `sokar vault unlock` first.'}

  # No default length: a bound that crept in would decide how often somebody is asked, and so would
  # its absence. Opening is refused until a length is chosen.
  Scenario: opening it asks how long, and chooses nothing for the person
    When I enroll this device as {'laptop'}
    And I close the answer
    And I shut the store
    And I close the answer
    And I begin opening the store with this device
    Then it cannot be opened until a length is chosen

  Scenario: opening it for an hour asks the machine for sixty minutes, and it is open
    When I enroll this device as {'laptop'}
    And I close the answer
    And I shut the store
    And I close the answer
    And I open the store with this device {'for an hour'}
    Then the machine was asked to open it for {60} minutes
    And it says {'The vault is open until'}
    When I close the answer
    Then the store's lock says {'The store is open. Shut it.'}

  Scenario: opening it until it is shut asks for no bound
    When I enroll this device as {'laptop'}
    And I close the answer
    And I shut the store
    And I close the answer
    And I open the store with this device {'until it is shut'}
    Then the machine was asked to open it without a bound

  Scenario: revoking another device keeps this one
    Given another device {'old phone'} can open the store
    When I enroll this device as {'laptop'}
    And I close the answer
    And I show the protected store
    And I revoke {'old phone'}
    Then it says {'"old phone" can no longer open the vault.'}
    And this device keeps the key the machine was given

  Scenario: revoking this device forgets its key here, and enrolling is offered again
    When I enroll this device as {'laptop'}
    And I close the answer
    And I show the protected store
    And I revoke {'laptop'}
    Then this device keeps no key for the machine
    And enrolling says {'This device cannot open the store yet. Enroll it so it can.'}

  # The way in when every device is gone. Revoking it from a window that may have lost its devices
  # is not offered; it is changed at the machine.
  Scenario: the recovery passphrase is listed and cannot be revoked from here
    When I show the protected store
    Then it says {'The passphrase, used at the machine.'}
    And the recovery passphrase cannot be revoked from here

  Scenario: a machine whose Sokar predates devices has the lock, and says why not enrolling
    Given the machine cannot enroll devices yet
    Then the store's lock says {'The store is open. Shut it.'}
    And enrolling is not offered
    When I show the protected store
    Then it says {'that arrives with Sokar B60'}

  # Whatever the title shows, the machine's menu has all three.
  Scenario: the machine's menu shuts the store too
    When I shut the store from the machine's menu
    Then it says {'The store is shut.'}
    When I close the answer
    Then the store's lock says {'The store is shut, and this device is not enrolled. Unlock it at the machine with `sokar vault unlock`, then enroll this device.'}
