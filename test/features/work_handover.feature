# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Reviewing what work pushed, and what it holds back

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  # Answered on the task itself since 2026-09-08. Nothing joins it to the gate: this container's
  # name is not the ref, and several containers over time share one.
  Scenario: work whose own commits are waiting for review says so on its detail
    When I select the work {'sokar-checkout-migrate'}
    And I open the selection
    Then it says {'its own work is waiting for review'}

  Scenario: work with nothing of its own waiting says that instead
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'nothing of its own is waiting'}

  Scenario: what a project pushed is readable file by file, without leaving the interface
    When I review what is waiting at the gate
    And I open the waiting push
    Then the review shows the file {'lib/money.dart'}
    And the review shows {'(value * 100).round()'}

  Scenario: the diff leaves the interface in one action, for reading somewhere else
    When I review what is waiting at the gate
    And I open the waiting push
    And I copy the diff
    Then what was copied mentions {'lib/money.dart'}
    And what was copied mentions {'(value * 100).round()'}

  Scenario: forwarding names the branch rather than guessing one
    When I review what is waiting at the gate
    And I open the waiting push
    And I forward it onto the branch {'fix-rounding'}
    Then it was forwarded onto {'fix-rounding'}
    And the status line mentions {'was forwarded to fix-rounding'}

  Scenario: dropping the request leaves the work in the mirror
    When I review what is waiting at the gate
    And I open the waiting push
    And I drop the request
    Then the status line mentions {'still in the mirror'}
    And nothing was forwarded

  Scenario: a project with no file recorded offers no gate, and names the reason
    When I select the project {'unrecorded'}
    And I open the command finder
    Then the command {'Review what is waiting at the gate'} is offered as unavailable

  # A screen full of waiting pushes reads as a wall, and it is not one: work can go straight
  # upstream by hand. The guard against that is a pre-push hook installed per clone, on whichever
  # machine somebody pushes from — which is not this interface's to install and often not even the
  # machine it is talking to.
  Scenario: the gate says what it does not see, rather than reading as a wall
    When I review what is waiting at the gate
    Then it says {'Work can also be pushed straight upstream by hand'}
    And it says {'per clone, on the machine you push from'}

  # Withdrawn entirely on 2026-09-08, not reworded into a smaller feature: Sokar does not know
  # what instruction files are called, and cannot merge them, because how an agent combines
  # several is that agent's rule. A screen guessing a set of filenames would answer "no
  # instructions" with confidence for a task that had them.
  Scenario: where somebody asks what an agent was told, the answer is not here
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'in the repository — nothing here has a view of them'}

  # `WorkHeld` landed on 2026-09-09. Asked for one task when it is opened, never while drawing a
  # list: it runs git inside the container, which on a list this interface redraws would be a call
  # per row.
  Scenario: what a running task holds that never reached the gate is on its detail
    Given the work holds {2} unpushed commits and {3} changed files
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'holds 2 unpushed commits and 3 changed files'}

  # Holding nothing and nobody having looked are different answers, and only one of them makes it
  # safe to remove a task without asking.
  Scenario: holding nothing is said as holding nothing
    Given the work holds {0} unpushed commits and {0} changed files
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'holds nothing that never reached the gate'}

  Scenario: a task nobody could look inside says that, not that it holds nothing
    Given nobody could look inside the work
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'nothing recorded what it held'}
    And it says {'killed, rebooted, or stopped by an older Sokar'}

  # "Holds" and "held" are different sentences: a stopped task's workspace is inside a container
  # that is no longer up, so the only source is what the stop wrote down.
  Scenario: a stopped task says what it held when it stopped, and when that was
    Given the work held {4} unpushed commits when it stopped
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'held 4 unpushed commits when it stopped'}
    And it says {'minutes ago'}

  # A wrong name is a refusal, never an unreadable answer — merging them would make a client's
  # mistake arrive as a legitimate reading.
  Scenario: a name the machine does not know is refused rather than read as unreadable
    Given the machine knows no such task
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then it says {'does not know a task called'}
