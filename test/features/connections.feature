# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: How a machine connects out, and giving it a credential

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  # The list holds no secret, so it is read with the vault shut — which is what tells "configured,
  # open the vault" from "nothing here".
  Scenario: connections are listed with the vault shut, one outside it marked not protected
    Given the store is shut
    And the machine connects to {'ssh://github.com'} with a key in the vault
    And the machine connects to {'https://gitlab.example/acme/'} with a token in a file
    When I choose the command {'Show how this machine connects out'}
    Then it says {'ssh://github.com'}
    And it says {'the vault is shut, so nothing can say whether its value is there'}
    And the connection {'https://gitlab.example/acme/'} is marked not protected
    And the connection {'ssh://github.com'} is not marked not protected

  # https may be a token or a user and password, so the address cannot decide it.
  Scenario: what a connection is, is chosen and never read off its address
    When I choose the command {'Show how this machine connects out'}
    And I add a connection to {'https://gitlab.example/acme/'}
    Then adding it is not offered yet
    When I choose it to be {'TOKEN'}
    Then adding it is offered

  Scenario: a token in the vault is stored by typing it into a terminal on the machine
    When I choose the command {'Show how this machine connects out'}
    And I add a connection to {'https://gitlab.example/acme/'}
    And I choose it to be {'TOKEN'}
    And I add it
    Then it was declared as {'TOKEN'} for {'https://gitlab.example/acme/'}, kept in {'VAULT'}
    And it says {'sokar vault put git.token.example'}
    When I type its value into a terminal on the machine
    Then a terminal runs {'sokar vault put git.token.example'} on the machine

  # A key is a file and the machine's prompt reads one line, so the file is sent on standard input.
  Scenario: an ssh key is sent from a file of this computer, and nothing of it is kept
    Given this computer has the key {'id_work'}
    When I choose the command {'Show how this machine connects out'}
    And I add a connection to {'ssh://gitlab.example'}
    And I choose it to be {'SSH_KEY'}
    And I add it
    And I send the key {'id_work'} to the machine
    Then the machine was given a key by {'sokar vault put git.ssh.example'}
    And the status line mentions {'is stored on'}

  Scenario: a pasted key is sent, and the field it was pasted into is emptied at once
    When I choose the command {'Show how this machine connects out'}
    And I add a connection to {'ssh://gitlab.example'}
    And I choose it to be {'SSH_KEY'}
    And I add it
    And I paste a key and send it
    Then the machine was given a key by {'sokar vault put git.ssh.example'}
    And nothing pasted is left on screen

  Scenario: forgetting a connection says the value is still there
    Given the machine connects to {'ssh://github.com'} with a key in the vault
    When I choose the command {'Show how this machine connects out'}
    And I forget the connection {'ssh://github.com'}
    Then it says {'Its value is still there'}
    And it says {'Remove that at the machine'}

  # What was pasted leaves the field the moment it is sent — also when storing it did not work,
  # which keeps the way to try again on screen.
  Scenario: a key that could not be stored is not kept in the field it was pasted into
    Given storing on the machine will fail
    When I choose the command {'Show how this machine connects out'}
    And I add a connection to {'ssh://gitlab.example'}
    And I choose it to be {'SSH_KEY'}
    And I add it
    And I paste a key and send it
    Then the status line mentions {'Storing the key did not work'}
    And the way to store it is still offered
    And nothing pasted is left on screen

