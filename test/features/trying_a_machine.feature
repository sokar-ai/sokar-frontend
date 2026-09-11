# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Trying a machine from the dialog, before it is watched

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    When I start watching another machine

  Scenario: a machine that answers says what it is, and nothing is left running
    When I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    Then the trial says {'Reached Sokar 0.1.0-mock'}
    And the forward raised for the trial was taken down

  Scenario: a forward ssh cannot raise says what ssh said
    Given raising a forward will fail with {'Host key verification failed.'}
    When I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    Then the trial says {'Host key verification failed.'}
    And the forward raised for the trial was taken down

  # The forward comes up either way; only connecting through it finds the far end empty.
  Scenario: a forward to a socket nobody serves points at the far end
    Given nothing answers on that machine
    When I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    Then the trial says {'nothing answers at /run/user/1001/sokar/sokard.sock on that machine'}
    And the forward raised for the trial was taken down

  Scenario: a machine that speaks something else says so
    Given the machine serves nothing this build knows
    When I choose {'Its socket is already forwarded'}
    And the forwarded socket is {'/tmp/sokard-remote.sock'}
    And I try the connection
    Then the trial says {'serves nothing this build understands'}

  Scenario: a socket already forwarded is tried without raising anything
    When I choose {'Its socket is already forwarded'}
    And the forwarded socket is {'/tmp/sokard-remote.sock'}
    And I try the connection
    Then the trial says {'Reached Sokar'}
    And nothing was raised for the trial

  Scenario: changing where it is takes the old answer away
    When I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    And I say it is at {'user@other.example.test'}
    Then the trial says nothing
