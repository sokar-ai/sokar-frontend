# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. Run by tool/e2e.sh against a real machine.
Feature: Reaching a real machine, reading it, and following a project

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

  # The whole way a project now comes to a machine, against the daemon rather than a fake: a
  # repository on that machine, followed through the dialog, read back with everything the
  # interface draws from it, and then no longer followed. In this file rather than one of its own:
  # each file launches the interface again, and a second launch joins the first and exits.
  Scenario: a repository followed through the dialog becomes a project, and stops being one
    Given the test machine is being watched
    And the test machine has a project repository {'e2e-follow'}
    When I follow it from the interface, unverified
    Then the interface says it is following it
    And the machine lists {'e2e-follow'} as followed unverified, with its repositories and their limits
    When I stop following {'e2e-follow'} from the interface
    Then the machine no longer lists {'e2e-follow'}

  # The wizard's check is the real daemon's dry run: it answers, and writes nothing. Storing a token
  # is typed at a terminal on the machine, which is a person's — so the run leaves before adding.
  Scenario: a token is checked by the real machine, and leaving writes nothing
    Given the test machine is being watched
    When I check a token for {'https://e2e.invalid/'} in the wizard, and leave it
    Then the wizard's check was answered by the machine
    And the machine no longer lists the connection {'https://e2e.invalid/'}

  # A key the machine already has is picked from what the machine lists, and declared where it lies.
  Scenario: a key the machine has is picked from its list and declared where it lies
    Given the test machine is being watched
    And the test machine has an ssh key of its own {'id_e2e'}
    When I declare the machine's own key for {'ssh://e2e.invalid/'} from the interface
    Then the machine lists the connection {'ssh://e2e.invalid/'} as the key it has
    When I forget the connection {'ssh://e2e.invalid/'} from the interface
    Then the interface says what still holds its value
    And the machine no longer lists the connection {'ssh://e2e.invalid/'}

  # An unknown host is a question for a person: its keys are shown, one is chosen and trusted, and
  # the follow is made again. The project itself needs a credential this account does not have, so
  # what is measured is that the host key stops being the answer.
  Scenario: a host never met is trusted from the follow, by the key its owner publishes
    Given the test machine is being watched
    And the test machine has never met {'github.com'}
    And the test machine has an ssh key of its own {'id_e2e'}
    And the test machine connects to {'ssh://github.com/'} with its own key
    When I follow {'git@github.com:sokar-ai/sokar-project.git'} as {'e2e-hostkey'} from the interface, unverified
    Then the interface shows the keys of {'github.com'}, with {'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'}
    When I trust {'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'} from the interface
    Then the machine knows {'github.com'} by the key {'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'}
    And the machine no longer lists {'e2e-hostkey'}
    And the connection {'ssh://github.com/'} is forgotten again

