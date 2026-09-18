# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Creating a project, checked by the machine that will run it

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: every question is in one place, and the sets offered are the ones this machine has
    When I describe a new project
    Then it says {'Its file goes where the machine keeps projects'}
    And it says {'What its work may reach'}
    And the sets offered are the ones installed here

  # None of this can be judged here: whether a name survives becoming an image tag and an nftables
  # set name, whether a set exists on that machine. An answer accepted in a dialog and refused at
  # the first task start is refused far from where it was given.
  Scenario: the answers are checked by the machine that will run them
    When I describe a new project
    And I answer the project questions
    Then the machine was asked to check the answers
    And nothing was created

  Scenario: an answer the machine rejects says which one and why
    Given the machine will reject {'name'} because {'a project name cannot contain a slash'}
    When I describe a new project
    And I answer the project questions
    Then it says {'a project name cannot contain a slash'}
    And creating it is not offered

  # Worth showing and not worth blocking on: a base image that is not on the machine yet will
  # simply be pulled, and refusing there would turn a note into a wall.
  Scenario: something worth knowing that does not block is not treated as a refusal
    Given the machine will warn about {'baseImage'} because {'not on this machine yet, so it will be pulled'}
    When I describe a new project
    And I answer the project questions
    Then it says {'not on this machine yet, so it will be pulled'}
    And creating it is offered

  Scenario: what would be written is shown before anything is created
    When I describe a new project
    And I answer the project questions
    Then it says {'security_class: "guarded"'}
    And it says {'It is an ordinary file'}
    And nothing was created

  Scenario: walking away leaves nothing behind
    When I describe a new project
    And I answer the project questions
    And I leave the project undescribed
    Then nothing was created

  # Creating is seconds and preparing is minutes. Joining them would make somebody who wanted a
  # project file wait ten minutes for a reason nobody stated.
  Scenario: creating says what is done and what is not
    When I describe a new project
    And I answer the project questions
    And I create the project
    Then it says {'is created'}
    And it says {'preparing its environment takes minutes'}

  # A refusal and never an overwrite: the file may be somebody's whole configuration, and this is
  # the one operation that would replace it with nothing to restore from.
  Scenario: a project file that is already there is never overwritten
    Given creating will find a file already there
    When I describe a new project
    And I answer the project questions
    And I create the project
    Then it says {'There is already a project file'}
    And it says {'Nothing was written'}

  Scenario: a project made here is the one chosen once it is made
    When I describe a new project
    And I answer the project questions
    And I create the project
    And I am done with the new project
    Then the project {'new-thing'} is selected

  # A path on a machine nobody sees from here is not a question a person can answer (QF22).
  Scenario: the machine chooses where the project file goes, and says where
    When I describe a new project
    And I answer the project questions
    Then it says {'Its file goes to /home/somebody/.config/sokar/projects/new-thing/project.yml'}
    And the machine was asked without a project file

  Scenario: a project file of one's own goes where it was put
    When I describe a new project
    And I put the project file at {'/home/somebody/work/new-thing/project.yml'}
    And I answer the project questions
    Then it says {'Its file goes to /home/somebody/work/new-thing/project.yml'}
    And the machine was asked with the project file {'/home/somebody/work/new-thing/project.yml'}


  # A Sokar from before QF22 reads a missing path as an empty one, which "already exists".
  Scenario: a Sokar that does not choose a place yet says so, rather than claiming a file is there
    Given the machine does not choose a place for project files yet
    When I describe a new project
    And I answer the project questions
    And I create the project
    Then it says {"This machine's Sokar does not choose a place for the project file yet"}
    And it says {'Put it somewhere else'}
