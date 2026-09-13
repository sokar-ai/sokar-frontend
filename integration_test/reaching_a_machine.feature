# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. Run by tool/e2e.sh against a real machine.
Feature: Reaching a real machine and reading what its daemon says

  Background:
    Given the interface is running

  Scenario: a machine added with a forward raised here is reached
    When I watch the test machine through a forward raised here
    Then the test machine is answering

  Scenario: every reply the interface reads can be read from the real daemon
    Given the test machine is being watched
    Then every reply it gives can be read

  Scenario: a machine is tried from the dialog before it is watched
    When I try the test machine from the dialog
    Then the trial says {'Reached Sokar'}
    And no forward raised for the trial is left
    And I put the dialog away

  # The forward comes up either way; only connecting through it finds the far end empty. The socket
  # sits in the login's own runtime directory, so nothing but the daemon is missing.
  Scenario: a socket nobody serves on the test machine is found by trying it
    When I try the test machine from the dialog with a socket beside its own that nobody serves
    Then the trial says {'nothing answers at'}
    And the trial says {'none.sock on that machine'}
    And no forward raised for the trial is left
    And I put the dialog away

  # ssh reports a wrong uid in the same words as a missing daemon, so the machine is asked which uid
  # the login has. uid 0 is never the account the test logs in as.
  Scenario: a socket in another user's runtime directory on the test machine is named as that
    When I try the test machine from the dialog with the socket {'/run/user/0/sokar/none.sock'}
    Then the trial says {'runtime directory (uid 0)'}
    And no forward raised for the trial is left
    And I put the dialog away
