# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F25 Task Templates

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: a recurring job is named, and becomes an action of its own
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Run the nightly tests'}
    And I keep it as {'nightly-tests'}
    And I leave without starting
    And I open the command finder
    Then the command finder names {'Run nightly-tests in checkout'}

  Scenario: starting from a named job is one action, and it runs what the job carried
    Given the job {'nightly-tests'} is already named
    When I choose the command {'Run nightly-tests in checkout'}
    And I start it
    Then the launch asked for the mode {'UNATTENDED'}
    And the launch asked it to {'Run the nightly tests'}

  Scenario: what the job asks for is editable before it runs
    Given the job {'nightly-tests'} is already named
    When I choose the command {'Run nightly-tests in checkout'}
    Then what to ask it says {'Run the nightly tests'}
    When I ask it to {'Run the nightly tests, and the slow ones too'}
    And I start it
    Then the launch asked it to {'Run the nightly tests, and the slow ones too'}

  Scenario: a job named in one project is not offered in another
    Given the job {'nightly-tests'} is already named
    When I select the project {'billing'}
    And I open the command finder
    Then the command finder does not name {'Run nightly-tests in checkout'}

  Scenario: a named job outlives the run that named it
    Given the job {'nightly-tests'} is already named
    When the app is restarted
    And I select the project {'checkout'}
    And I open the command finder
    Then the command finder names {'Run nightly-tests in checkout'}
