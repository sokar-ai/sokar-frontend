# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F12 Interactive Session Attach

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'billing'}
    And I select the work {'sokar-billing-shell'}

  Scenario: a session is one action from where the work is listed
    When I work in it by hand
    Then the session runs {'sokar task attach sokar-billing-shell'}

  Scenario: a machine reached over ssh runs the same verb, through a terminal of its own
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And I watch it
    And I switch to the machine {'the build machine'}
    And I select the project {'billing'}
    And I select the work {'sokar-billing-shell'}
    And I work in it by hand
    Then the session runs {'ssh -t user@build.example.test sokar task attach sokar-billing-shell'}

  Scenario: what the far end prints is what is on the screen
    When I work in it by hand
    And the session prints {'root@sokar-billing-shell:/work#'}
    Then the session shows {'root@sokar-billing-shell:/work#'}

  Scenario: what is typed reaches the far end
    When I work in it by hand
    And I type {'ls -l'} into the session
    Then the session was sent {'ls -l'}

  # The same work F17 refuses to widen, and deliberately so: the class governs egress — what
  # resolves and what leaves — and a person typing is neither. Offline is precisely the project
  # where somebody has to work by hand, because the agent reaches nothing.
  Scenario: an offline project may be worked in by hand, though it may not be widened
    When I open the command finder
    Then the command {'Let this work reach something new'} is offered as unavailable
    When I work in it by hand
    Then the session runs {'sokar task attach sokar-billing-shell'}

  Scenario: work an agent is driving has no session to join, and says so before it is pressed
    Given I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    When I open the command finder
    Then the command {'Work in it by hand'} is unavailable because {'An agent is what runs in this'}

  # Against work whose mode nothing recorded, deliberately: nothing else can take the action
  # away, so what is measured is the running check on its own. A scenario against a stopped
  # unattended run passed with that check deleted — the agent rule was doing the work.
  Scenario: work that has stopped has no session, and points at starting it again
    When I select the work {'sokar-billing-audit'}
    And the work {'sokar-billing-audit'} is dead
    And I open the command finder
    Then the command {'Work in it by hand'} is unavailable because {'Starting it again brings back the workspace'}

  # The same rule the rest of the frame follows, so a session is not a special case somebody has
  # to learn: beside the work where there is room for both, and on its own where there is not.
  #
  # 1600 rather than 1200: the frame branches on the width **under the rail**, not on the
  # window's, and an extended rail is 256 of them. A window that is only just wide enough is one
  # where the work list is already gone.
  Scenario: on a wide window the work stays visible beside the session
    When the window is {1600} pixels wide
    And I work in it by hand
    Then the session is on screen
    And the work {'sokar-billing-shell'} is listed

  Scenario: on a narrow window the session has the frame to itself, and leaving gives it back
    When the window is {700} pixels wide
    And I work in it by hand
    Then the session is on screen
    And the work pane is not shown
    When I put the session away
    Then the work {'sokar-billing-shell'} is still selected

  Scenario: leaving a session puts somebody back where they were, with the same work selected
    When I work in it by hand
    And I put the session away
    Then the work {'sokar-billing-shell'} is still selected

  # Found by asking where the key went rather than by assuming: the frame's `Escape` closed the
  # pane and the far end never saw it, which would have made `vim` unusable inside a session.
  Scenario: Escape belongs to what is running, and never closes the session
    When I work in it by hand
    And I close what is open
    Then the session is on screen
    And {1} sessions are open

  Scenario: two sessions are open at once, and each says which work it is
    When I work in it by hand
    And I put the session away
    And I select the work {'sokar-billing-audit'}
    And I work in it by hand
    Then {2} sessions are open
    And the session names {'sokar-billing-shell'}
    And the session names {'sokar-billing-audit'}

  # One container holds one session, so asking again returns to the one that is there. A second
  # way in to the same work would draw the same screen twice and let somebody type into either.
  Scenario: asking for a session twice returns to the one that is already open
    When I work in it by hand
    And I put the session away
    And I work in it by hand
    Then {1} sessions are open

  Scenario: the screen says that closing the window leaves the session running
    When I work in it by hand
    Then it says {'Closing this window leaves the session running'}

  Scenario: a session the machine would not open says so, without claiming the work stopped
    When I work in it by hand
    And the session ends with {69}
    Then it says {'The machine would not open a session here'}
    And the work was never stopped

  Scenario: a connection that never happened is told apart from work that refused
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And I watch it
    And I switch to the machine {'the build machine'}
    And I select the project {'billing'}
    And I select the work {'sokar-billing-shell'}
    And I work in it by hand
    And the session ends with {255}
    Then it says {'The connection to the build machine failed'}

  Scenario: leaving a session closes the way in and stops nothing
    When I work in it by hand
    And I leave the session
    Then no session is open
    And the work was never stopped

  Scenario: somebody who typed exit is not told that anything went wrong
    When I work in it by hand
    And the session ends with {0}
    Then it says {'This way in is closed. The work is where you left it.'}
