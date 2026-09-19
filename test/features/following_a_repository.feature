# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: A project comes to a machine by following its repository

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  # How the commits are checked decides who controls what this machine runs. Nobody's default.
  Scenario: how its commits are checked is chosen, never assumed
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    Then following it is not offered yet
    When I choose to check its commits against a key
    Then following it is not offered yet
    When I give the key {'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'}
    Then following it is offered

  Scenario: a pinned key goes with the follow, and the project is there at once
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    And I choose to check its commits against a key
    And I give the key {'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'}
    And I follow it
    Then the follow was sent with the key {'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'}
    And it says {'Following, at c0ffee1'}
    When I go to the project it made
    Then the project {'payments'} is the one chosen

  Scenario: following unverified says what that gives away before it is chosen
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    Then it says {'Anybody who can push to the repository decides what this machine runs'}
    When I choose to follow it unverified
    And I follow it
    Then the follow was sent unverified

  Scenario: a commit the machine will not take is said, and no project is made of it
    Given the next follow is refused as {'NOT_SIGNED'}
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    And I choose to follow it unverified
    And I follow it
    Then it says {'is not signed'}
    And there is no project {'payments'}

  # Its owner rebasing, or somebody re-serving an older signed configuration to put back a rule that
  # was taken away: nothing here can tell which, so it is never taken without a person saying so.
  Scenario: a rewritten history is taken only as a second decision
    Given the next follow finds a rewritten history
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    And I choose to follow it unverified
    And I follow it
    Then it says {'Nothing here can tell which'}
    And the follow accepted no rewrite
    When I take the rewritten history
    Then the follow accepted the rewrite

  # The fingerprint is what a refused signature shows, so it is what somebody has in hand to pin.
  Scenario: a key can be pinned by the fingerprint a refusal showed
    When I follow a repository
    And I name it {'payments'} at {'git@example.org:payments.git'}
    And I choose to check its commits against a key
    Then it says {'or its fingerprint'}
    When I give the key {'SHA256:9xQeTbL1'}
    And I follow it
    Then the follow was sent with the key {'SHA256:9xQeTbL1'}
