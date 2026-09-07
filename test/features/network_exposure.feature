# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F17 Network Exposure Control

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: a blocked connection turns up without anybody going to look for it
    When work is blocked reaching {'api.example.test:443'}
    Then the rail says {'1'} is waiting

  Scenario: what was attempted, by which work, and which rule stopped it
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    Then it shows the destination {'api.example.test:443'}
    And it names the work and the rule

  Scenario: several pieces of work are watched in one view, not one view each
    When work is blocked reaching {'api.example.test:443'}
    And other work is blocked reaching {'files.example.test:22'}
    And I go to what is blocked
    Then both are shown together

  Scenario: letting one through tells the work that is waiting
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And I let it through
    Then the answer sent was {'allow'}

  Scenario: keeping one blocked is a separate answer, not a silence
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And I keep it blocked
    Then the answer sent was {'deny'}

  Scenario: work nothing is enforcing is marked wherever it appears
    When I select the project {'billing'}
    Then the work {'sokar-billing-audit'} is marked as unenforced
    And the work {'sokar-billing-shell'} is not marked as unenforced

  Scenario: letting one through says the host is reachable, not that the attempt succeeded
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And I let it through
    And the answer comes back
    Then it says {'the attempt that was refused is gone'}

  Scenario: a destination asked about again says why that is not a mistake
    When work is blocked reaching {'cdn.example.test:443'}
    And I go to what is blocked
    And I let it through
    And the answer comes back
    And work is blocked reaching {'cdn.example.test:443'}
    Then it says {'remembered per address'}

  Scenario: a question that ran out says so rather than quietly disappearing
    When work is blocked reaching {'api.example.test:443'}
    And I go to what is blocked
    And the question runs out
    Then it says the question ran out
    And nothing is waiting any more

  Scenario: what running work may reach is changed from where that work is listed
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I choose the command {'Let this work reach something new'}
    And I ask it to reach {'files.example.test'}
    And I choose {'Just this run'}
    And I show what that would grant
    Then it lists the grant {'files.example.test'}
    And nothing has been granted yet

  Scenario: how far the change goes is chosen, never defaulted
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I choose the command {'Let this work reach something new'}
    And I ask it to reach {'files.example.test'}
    Then showing what it would grant is not offered yet

  Scenario: the scope that was chosen is the scope that is sent
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I choose the command {'Let this work reach something new'}
    And I ask it to reach {'files.example.test'}
    And I choose {'This run and the project file'}
    And I show what that would grant
    And I grant it
    Then the scope sent was {'RUN_AND_PROJECT'}

  Scenario: a grant says the host is reachable next time, not that what failed will now work
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I choose the command {'Let this work reach something new'}
    And I ask it to reach {'files.example.test'}
    And I choose {'Just this run'}
    And I show what that would grant
    And I grant it
    Then it says {'Reachable from the next attempt'}
    And it says {'This run only'}

  Scenario: a run widened with no project file to write is a partial success, not a failure
    When the project file cannot be found
    And I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I choose the command {'Let this work reach something new'}
    And I ask it to reach {'files.example.test'}
    And I choose {'This run and the project file'}
    And I show what that would grant
    And I grant it
    Then it says {'Granted for this run'}
    And it says {'Reachable from the next attempt'}

  Scenario: work that is not running says why it cannot be widened
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-migrate'}
    And I open the command finder
    Then the command {'Let this work reach something new'} is offered as unavailable

  Scenario: an offline project is never offered the action
    When I select the project {'billing'}
    And I select the work {'sokar-billing-shell'}
    And I open the command finder
    Then the command {'Let this work reach something new'} is offered as unavailable
