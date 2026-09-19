# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Starting work with an agent, a mode and a credential

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    And I select the project {'checkout'}

  # Pressing start is answered at once; the machine is asked behind the open dialog. Waiting for it
  # first left the press without any sign, and it was pressed twice.
  Scenario: the start dialog opens at once, and says it is still asking the machine
    Given reading the agents is slow
    When I start work in this project
    Then it says {'Asking the machine what it has'}
    When the machine has answered
    Then it does not say {'Asking the machine what it has'}

  Scenario: work is started with a name, an agent and a mode
    When I start work in this project
    And I call it {'schema-work'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch was called {'schema-work'}
    And the launch asked for the mode {'SHELL'}
    And the launch named the project {'checkout'}

  Scenario: a name is optional, so nothing has to be invented before starting
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch left the naming to the machine

  # The operator's Foo Bar was sent, the image was built, and only podman's create refused the name.
  Scenario: a name no container could have is refused before anything starts
    When I start work in this project
    And I call it {'Foo Bar'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'cannot hold a space'}
    And starting is not offered yet

  # A case-insensitive filesystem makes Foo and foo one git ref.
  Scenario: a name in upper case is refused, because two of them could be one ref
    When I start work in this project
    And I call it {'Schema-Work'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'lowercase'}
    And starting is not offered yet

  Scenario: a name of other characters, or with a hyphen at its edge, is refused
    When I start work in this project
    And I call it {'schema_work-'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'starts and ends with a letter or a digit'}
    And starting is not offered yet

  # A login container is sokar-login-<digits>.
  Scenario: a name of only digits is refused
    When I start work in this project
    And I call it {'123'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'only digits'}
    And starting is not offered yet

  # The container name holds the prefix, and the task's longest socket path has to fit.
  Scenario: a name too long for its project is refused, saying how long it may be
    When I start work in this project
    And I call it {'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'at most 65 fit'}
    And starting is not offered yet

  # The machine's rule is the authority, and its sentence carries a name that would do.
  # Named last, so only typing it can have asked the machine about it.
  Scenario: a name the machine refuses is refused in its words
    Given the machine refuses the name {'login-7'} saying {'kept for login containers - login7 would do'}
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I call it {'login-7'}
    Then the name is refused saying {'login7 would do'}
    And starting is not offered yet
    And the machine was asked about the name {'login-7'}

  Scenario: the mode is chosen, never assumed on somebody's behalf
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then starting is not offered yet

  Scenario: an unattended run is not started without being told what to do
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    Then starting is not offered yet

  Scenario: a prompt belongs to an unattended run and to nothing else
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then what to ask it cannot be filled in

  Scenario: what was chosen is what is sent
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I start it
    Then the launch asked for the mode {'UNATTENDED'}
    And the launch asked it to {'Fix the rounding and add a test'}

  Scenario: an unattended run goes to the session, so leaving the dialog does not stop watching
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I start it
    And the operation prints {'agent: reading lib/money.dart'}
    Then the operation shows {'agent: reading lib/money.dart'}

  Scenario: a finished unattended run is continued with what it was asked to do last time
    When I select the work {'sokar-checkout-migrate'}
    And I continue this work
    Then what to ask it says {'Fix the rounding in Money.pennies'}

  Scenario: work that is still running is not offered a new prompt
    When I select the work {'sokar-checkout-shell'}
    And I open the command finder
    Then the command {'Continue this work with a new prompt'} is offered as unavailable

  Scenario: an agent that could not be read is named rather than left out
    Given one agent on the machine cannot be read
    When I start work in this project
    Then it says {'could not be read'}

  Scenario: a prompt typed and then set aside is not sent with a mode that has no use for it
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch asked for the mode {'SHELL'}
    And the launch was asked for nothing in particular

  Scenario: a missing credential is named before anything is started
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'The vault holds no credential called a-provider'}
    And nothing was started

  # A missing credential is stored from where it was found missing, by the line the machine names
  # for its provider, in a terminal there — and then the machine is asked again.
  Scenario: a missing credential is stored from the start dialog, and starting is asked about again
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I store the credential from the start
    Then a terminal runs {'sh -c sokar vault put a-provider'} on the machine
    When the unlock terminal ends and is put away
    Then whether work can start is asked again

  # A login prints its page as an OSC 8 link. It is offered to be opened here — never opened by
  # itself, and never anything but a web address.
  Scenario: a link the terminal marks is opened in the browser here with a press, and only then
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I store the credential from the start
    And the terminal prints a link to {'https://claude.com/cai/oauth/authorize?code=true'}
    Then nothing was opened in the browser
    When I open the link to {'https://claude.com/cai/oauth/authorize?code=true'}
    Then the browser was given {'https://claude.com/cai/oauth/authorize?code=true'}

  Scenario: a link that is not a web address is never offered
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I store the credential from the start
    And the terminal prints a link that would run {'file:///usr/bin/xcalc'}
    Then the terminal offers no link

  # The agent's own login, where it declares one: its page is a link to open here, and its reply
  # to localhost is forwarded to the machine for as long as the login's terminal is open.
  Scenario: an agent that declares a login is logged in from the start, its reply forwarded
    Given the vault holds no credential for what a run would use
    And the agent {'an-agent'} logs in by its own login
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I log in with the agent from the start
    Then a terminal runs {'sokar vault login --agent an-agent'} on the machine
    When the login prints its page {'https://claude.com/cai/oauth/authorize'} and its reply port {'42017'}
    Then the reply port {'42017'} is forwarded
    And nothing was opened in the browser
    When I open the link to {'https://claude.com/cai/oauth/authorize'}
    Then the browser was given {'https://claude.com/cai/oauth/authorize'}
    When the unlock terminal ends and is put away
    Then the reply forward is taken down
    And whether work can start is asked again

  # An agent may print a link of its own beside the machine's. The machine marks its own, and that is
  # the one offered first: its reply comes back without a code. The other stays, for an agent without one.
  Scenario: the machine's login page is offered first, and a link of the agent's own below it
    Given the vault holds no credential for what a run would use
    And the agent {'an-agent'} logs in by its own login
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I log in with the agent from the start
    And the agent prints a link of its own to {'https://claude.com/cai/oauth/authorize?code=true'}
    And the login prints its page {'https://claude.com/cai/oauth/authorize'} and its reply port {'42017'}
    Then the first link offered says {'Sign in: the reply comes back here'}, and opens {'https://claude.com/cai/oauth/authorize'}
    And it says {'Another link the program printed'}

  Scenario: an agent that declares no login is not offered one
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then logging in is not offered

  Scenario: the credential is stored by the command the readiness answer names
    Given starting says the credential is stored by {'sokar vault put a-provider'}
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I store the credential from the start
    Then a terminal runs {'sokar vault put a-provider'} on the machine

  # Asked behind an open dialog nobody awaits: a failure let through there reaches nobody but the
  # console, and the dialog sits as if it had asked nothing.
  Scenario: a machine that fails to say whether work can start is said in the dialog
    Given the machine fails to say whether work can start, with {'the vault could not be read'}
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'The machine could not say whether work can start: the vault could not be read'}

  # Choosing to work by hand is choosing to be in the work: once it is up, its session opens,
  # rather than a log of the start somebody then has to leave to find the work.
  Scenario: work started to be driven by hand opens its session once it is up
    When I start work in this project
    And I call it {'schema-work'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    And the start brings up {'sokar-checkout-schema-work'} in {'checkout'}, running {'SHELL'}
    Then the session on screen is {'sokar-checkout-schema-work'}

  # An unattended run has nobody at it: its log is what there is to watch.
  Scenario: an unattended run opens no session when it is up
    When I start work in this project
    And I call it {'nightly'}
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'run the tests'}
    And I start it
    And the start brings up {'sokar-checkout-nightly'} in {'checkout'}, running {'UNATTENDED'}
    Then no session was opened

  Scenario: a locked vault is a different sentence, and points at the machine
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'Unlock it at the machine'}
    And it says {'a daemon has no terminal'}

  Scenario: choosing a provider is not storing a secret
    Given the agent names no default provider
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'this is a provider, not a secret'}

  Scenario: an unattended run that cannot authenticate is not offered at all
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding'}
    Then starting is not offered yet
    And it says {'no container, no workspace, nothing to clear up'}

  Scenario: an interactive run is offered anyway, and says what it will cost
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then it says {'a container you will have to clear up'}


  # Sokar B67, the operator's decision: work always starts in a named repository, and none is chosen
  # for anybody — not even when there is only one.
  Scenario: work starts in a repository somebody chose, never in one chosen for them
    Given the project {'checkout'} has the repositories {'checkout, payments-api'}
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then no repository is chosen yet
    And starting is not offered yet
    And nothing warns about starting
    When I choose the repository {'payments-api'}
    Then the machine was asked whether work can start in {'payments-api'}
    When I start it
    Then the launch was in the repository {'payments-api'}

  # A repository still to choose is not a refusal, even for a run nobody watches.
  Scenario: an unattended run waiting for its repository is not told it would be refused
    Given the project {'checkout'} has the repositories {'checkout, payments-api'}
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding'}
    Then starting is not offered yet
    And nothing warns about starting

  # A Sokar older than B67 names no repositories and is sent none.
  Scenario: a machine that names no repositories is asked for none
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch named no repository

  # Continuing is more of the same work, so it goes on where that work is — not a new choice.
  Scenario: work continued goes on in the repository it worked in
    Given the project {'checkout'} has the repositories {'checkout, payments-api'}
    And the work {'sokar-checkout-migrate'} works in the repository {'payments-api'}
    When I select the work {'sokar-checkout-migrate'}
    And I continue this work
    Then the repository {'payments-api'} is chosen
