# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Adding a machine through a wizard that starts from what you have

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    When I open the machine dialog

  Scenario: the first page asks for a name and one of three kinds
    Then it says {'Its socket is already forwarded'}
    And it says {'Raise the forward for me'}
    And it says {'A new machine'}

  # Nothing is preselected: the kinds are different commitments, and a default would choose one.
  Scenario: the wizard goes on only with a name and a kind
    When I say it is called {'the build machine'}
    Then the wizard cannot go on yet
    When I choose {'Raise the forward for me'}
    And I go on
    Then its socket there is not filled in

  Scenario: a kind without a name does not go on either
    When I choose {'Its socket is already forwarded'}
    Then the wizard cannot go on yet

  Scenario: going back keeps what was said, and another kind can be chosen
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I go on
    And I say it is at {'user@build.example.test'}
    And I go back
    And I choose {'Its socket is already forwarded'}
    And I go on
    And the forwarded socket is {'/tmp/sokar-build.sock'}
    And I watch it
    Then nothing was raised for {'the build machine'}

  # BatchMode fails on an unknown key rather than asking, and a key accepted unseen is the one step
  # somebody in the middle needs. So it is shown, and trusting it is a separate act.
  Scenario: a host reached for the first time shows its key before anything logs in
    Given the host key of {'user@build.example.test'} is not known yet
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    Then I am shown the host key {'SHA256:uNiQuEfInGeRpRiNtOfThEbUiLdMaChInE0123456789'}
    And nothing was raised for the trial
    When I trust the host key
    Then the host key of {'build.example.test'} was written
    And the trial says {'Reached Sokar'}

  Scenario: a host key that is not trusted is never written, and nothing is tried
    Given the host key of {'user@build.example.test'} is not known yet
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    And I do not trust the host key
    Then no host key was written
    And the trial says {'was not trusted, so nothing was tried'}
    And nothing was raised for the trial

  Scenario: watching without trying asks about the key too
    Given the host key of {'user@build.example.test'} is not known yet
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    Then I am shown the host key {'SHA256:uNiQuEfInGeRpRiNtOfThEbUiLdMaChInE0123456789'}
    When I do not trust the host key
    Then no host key was written
    And nothing was raised for {'the build machine'}

  Scenario: a host already known is not asked about
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I try the connection
    Then the trial says {'Reached Sokar'}
    And no host key was written

  # A socket somebody else forwarded names no host, so there is no key of one to ask about.
  Scenario: a socket already forwarded is never asked about a host key
    When I say it is called {'the build machine'}
    And I choose {'Its socket is already forwarded'}
    And the forwarded socket is {'/tmp/sokar-build.sock'}
    And I try the connection
    And I watch it
    Then no host key was asked about
