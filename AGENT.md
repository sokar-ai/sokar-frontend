# Working on the Sokar frontend

The interface people use to work with a [Sokar](https://github.com/sokar-ai/sokar) backend, in
Flutter. This file is the working knowledge: the rules, the traps, and the things that were
measured rather than assumed. What must be *true for a person using it* is in
[requirements](requirements/README.md); what it is *made of* is in
[design](requirements/design.md).

## Start here

The frame and the client exist; the rest of the product does not. In order:

1. **[Backend API](doc/Backend-API.md)** — how to talk to the daemon, and the compatibility
   rules. Do not write a call before reading it.
2. **[What the contract does not yet cover](doc/Contract-Gaps.md)** — the short list of what the
   backend has no method or field for yet. Read it before picking a requirement, not after
   designing a screen for one.
3. **[Design](requirements/design.md)** — what this is made of and why: Flutter, testing, the
   mock, packaging.
4. **[Requirements](requirements/README.md)** — the work, ordered, with a **Backend** column
   saying what is reachable today.

Green means `dart analyze` at "No issues found!", `flutter test` passing, and
`flutter build linux --release` producing a bundle — measured 2026-09-07 at 13 s and 23 MB.

The frame is built: `lib/src/app/` is the state the frame is
drawn from, `lib/src/ui/` the frame itself. To open it against no daemon at all:

```
dart tool/mock_daemon.dart          # prints the socket, and a situation to choose
SOKAR_SOCKET=<that socket> flutter run -d linux
```

`SOKAR_SOCKET` names the machine the interface starts with, which is how the mock is opened;
more machines are added from the menu bar, under Machines.

## The one architectural rule

**Everything goes through the varlink contract. Nothing shells out to `sokar`.**

**And a method existing is not the requirement being covered.** Four requirements sat in the
old *ready* column of [Contract-Gaps](doc/Contract-Gaps.md) because the obvious method existed;
walking them against the IDL parameter by parameter on 2026-09-07 found `Start` has no `mode` and
no `prompt`, `Stop` has no rename beside it, `Tail` has nothing that lists the logs, and every
gate method wants a **project file path** that nothing on this side can produce. Check the
parameters, not the method name.

The daemon serves the domain directly over a unix socket. An interface that ran the CLI and
parsed its output would be a second implementation of every refusal the product makes — and
those refusals are the product: `Stop` declining to remove a task holding unpushed work is not
an error path, it is the feature. Two implementations of it is one that eventually destroys
someone's work.

There is also **no shared code with the backend**. No generated package, no jar, no vendored
client. The only thing crossing the boundary is `org.fuin.sokar.Tasks1`, which the daemon
serves from itself. Read [Backend API](doc/Backend-API.md) before writing a call.

## Talking to the backend

- **The contract is served, not copied.** `dart tool/contract.dart` prints it from a running
  daemon. Do not check a copy into this repository: it would be a second source of truth that
  nothing keeps honest, and the backend has a test that keeps the real one honest.
- **Local and remote differ by one string** — the socket path. Locally
  `$XDG_RUNTIME_DIR/sokar/sokard.sock`; remotely an SSH forward of the same socket. Measured:
  the identical client works against both, and streaming survives the forward with an event
  arriving 0.4 s after it was raised on the far machine. **Never write a second transport.**
- **One call at a time per connection.** The framing carries no request ids. Open a connection
  per stream; that is what it is for and it costs nothing.
- **Errors are answers.** `HOLDS_WORK`, `MethodNotFound`, `NoClearance` — these get real places
  in the interface, not a generic error toast.
- **`Prompts` has a deadline.** A task is *blocked* while a clearance prompt goes unanswered,
  and the watcher gives up on its own timeout. It is the one place where interface latency costs
  something real, which is why it is a stream and not a poll.
- **`Prompts` carries answers as well as questions.** The same destination arrives a second time
  with `verdict` set — `allow`, `deny` or `timeout`. **Match it to the open question by `task` and
  `key` alone** (`Prompt.identity`) and update that row; anything rendering every reply as a new
  item shows each blocked destination twice. Three traps behind it: `at` is the block time on a
  question and the decision time on an answer, `prefix` is empty on an answer, and a client sees
  the echo of its own `Decide` — do not apply it twice. `verdict: "timeout"` is the only way to
  learn a prompt expired, because nothing asks about it again; show it as expired and **keep it
  answerable**, since `Decide` still works and still takes effect.
- **These events carry undeclared fields** — `shown`, `project`, `source` among them. They are not
  contract and may change without notice. If one would be useful, ask for it to be declared.

## Staying compatible with older backends

A fleet is not upgraded at once, so this will meet daemons older than itself. Three rules, stated
in full at the top of the IDL:

- **Pick the interface, do not compare versions.** Read `GetInfo`, take the highest
  `org.fuin.sokar.TasksN` you understand. Within one `N` the interface only grows; a breaking
  change becomes `N+1` and is served beside `N` for at least one release.
- **Degrade per feature, not per connection.** A method an older daemon lacks answers
  `MethodNotFound`. Disable that one feature; keep the rest.
- **Unknown values must not be fatal.** Ignore reply fields you do not recognize and render an
  unrecognized enum value rather than throwing on it. Adding an enum value is explicitly *not* a
  breaking change, and `Outcome` will gain entries. **A generated Dart enum with no fallback case
  is how this rule gets broken** — it will look correct until a routine backend release.

The build version from `GetInfo` is for display and bug reports. Never gate a feature on it.

## Stop keeps, Remove destroys, Start decides

Agreed with the Sokar side on 2026-09-11, as one cut on both sides with no shim between.

- **`Stop` keeps the task**: its container is its workspace. `Remove` destroys it and inherits
  the refusals (`HOLDS_WORK`, `NOTHING_KNOWS`, and `STILL_RUNNING` for a running one).
- **`Start` creates or brings back**, decided by the task's state; `Resume` is gone.
- **What `Start` would do is on the task in `List`/`Watch`** (`startAction`), so a refusal is
  offered as unavailable with its reason and never found by pressing. An empty value is a daemon
  too old to say, and the runtime's `running` decides.
- **A refused `Start` is an ordinary final reply** with `action` set, and must not read as a start
  that worked.
- **`Start` takes the project file and the name within the project** (`Task.task`), never the
  container name, because `CREATE` has no container yet. That name is carried, never cut from
  `Task.name`. `now` returns without waiting for a build; over varlink nothing attaches.

**Until the first release the IDL's compatibility rules are not in force** (the operator's ruling,
2026-09-11). A method may be renamed, removed or given a new meaning in place, but only after both
sides agree on the channel, and both change together. The three rules above for reading a reply
still hold; the exemption ends when the interface is frozen by the first release.

## Code

- **Dart 3.13, Flutter 3.47 stable.** Pinned in `pubspec.yaml`.
- **Comments say why, not what.** The useful ones name a constraint, a measurement, or a bug
  that already happened. An inline comment is **one line** — not one sentence over three. The
  reasoning that does not fit is a finding, and findings go in this file where they can be found
  without reading the code.
- **US English** in prose, comments, identifiers and anything the interface shows: behavior,
  recognize, serialize, canceled, analyze, artifact. The early files were written the other way
  and were swept, so a British spelling appearing now is a new one — the sweep is not a thing to
  repeat.
- Prefer a small named widget or method over a comment explaining a block.

## Tests

**Gherkin `.feature` files, generated into real widget tests by
[`bdd_widget_test`](https://pub.dev/packages/bdd_widget_test).** Run `dart run build_runner build`
after adding or editing a feature. Why this package and not the better-known ones is in
[design](requirements/design.md) — the short version is that every other Gherkin option for Dart
is a parallel runner whose scenarios never reach JUnit XML, and most of them predate Dart 3.

- **The requirement id goes in the `Feature` line, never in a scenario name.** It becomes the
  JUnit group, which makes the CI test report a traceability matrix for free. Reworded criteria
  then do not churn ids.
- **Step wording is an API, and two features sharing words must mean the same thing by them.**
  `it warns {...}` was written for one feature's cost banner and reused by another for something
  else entirely, which then looked for the wrong widget. Name a step for what it asserts.
- **Step wording is an API.** `Given the app is running` resolves to
  `test/features/step/the_app_is_running.dart` — beside the feature — for every feature that uses
  it. Phrase a step the way you want to reuse it and vary the data rather than the sentence; a
  step reworded for one feature silently forks into a second file. An unmet step is scaffolded as
  a stub referencing `MyApp`, which fails to compile until it is written.
- **Generated tests are committed**, and CI proves they are current by running `build_runner` and
  failing on a diff. Do not edit them.
- **Every requirement must be named by at least one feature**, and no feature may name one that
  no longer exists. `test/requirements_coverage_test.dart` asserts both. Bind at requirement
  level, never at bullet level.
- **`pending` in that file is a ratchet, not a suppression list.** It must equal the uncovered
  set exactly, so covering a requirement fails the build until it is removed from the list — and
  removing one early fails too. Shrink it; never grow it without saying why.
- **Every guard must be proven to fail.** A test that has never failed is a test nobody has
  checked. When adding a rule, violate it once deliberately and watch it break. This is not
  ceremony: it has already paid for itself here. Removing the "a stream that ends without a final
  reply is an error" guard did **not** fail the suite — the test covering it was passing through
  the socket-error path instead, and the graceful-close path had no test at all. Two tests exist
  now because the mutation was actually run.
- **Test observable behavior**, not internals — what is on screen, what went down the socket.
- **Three levels, and each proves something the others cannot.** They are not redundant and
  nothing above the first one can catch a mistake below it:
  1. **`test/features/`** — the frame, in widget tests, against `FakeBackend`. A widget test runs
     on a fake clock and real socket input never completes under it, so this level cannot use a
     socket at all.
  2. **`test/client/`** — the client and the stand-in, over a **real unix socket** against
     `MockDaemon`. `mock_machine_test.dart` holds `MockMachine` — what
     `tool/mock_daemon.dart` serves, and what a person opens the interface against — to the
     behavior the frame is built on.
  3. **`test/client/live_daemon_test.dart`** — the client against a **real `sokard`**, skipped
     unless `SOKAR_SOCKET` points at one. The only test that can say the hand-written client
     agrees with the daemon rather than with our reading of the IDL. Pointed at the mock it fails,
     which is how it is known not to be vacuous.
- **A stand-in must act on what it is told, not answer canned.** `Stop` answered *removed* and
  went on listing the task, so a working interface looked like one where nothing happens — found
  by hand, in a minute, with the whole suite green. Both stand-ins act now, and a scenario asserts
  the row goes rather than only that the outcome was reported. **Assert the effect, not the
  report.**
- **A test that needs a real daemon is not a unit test.** Unit and widget tests must run with no
  backend, no podman and no container runtime present. That is what the mock is for.
- **The mock daemon does not work inside `testWidgets`.** Measured 2026-09-07: a widget test runs
  on a fake clock, and a `MockDaemon` connection opened inside one never completes — `flutter test`
  hangs until it is killed, `tester.runAsync` included, whether the daemon is started in the same
  `runAsync` as the call or an earlier one. So the two levels are tested at different seams: the
  **wire** over a real socket against the mock, in plain `test()` in `test/client`; the **frame**
  against a `FleetBackend` stub, in `testWidgets`. Do not try to put a socket back into a widget
  test — it looks like it should work, and it costs an afternoon.
- **Never commit with a failing suite.** Run `flutter test` as its own step, read the result,
  then commit. Chaining test-and-commit in one command is how red commits get into a history.

`dart tool/test_report.dart` turns a run into `build/test-report.html` — the same traceability
matrix, plus the requirements nothing covers yet, in one file with no external anything. It reads
the `--machine` JSON rather than the JUnit XML: the XML is made from that JSON, so reading the
source is one fewer thing that can disagree, and it keeps the failure text the XML flattens away.

Build server output, verified end to end:

```
flutter test --machine | tojunit > build/test-results.xml
```

`tojunit` comes from `junitreport` (`dart pub global activate junitreport`). One trap already
met: `build_runner`'s `--delete-conflicting-outputs` has been removed and is silently ignored.

## The client

`lib/src/wire/` is the varlink framing, `lib/src/client/` the typed calls and models,
`lib/client.dart` the barrel. **Nothing else in this application may open a socket.**

Three things are decided there rather than left to callers, because leaving them to callers is
how they get forgotten:

- **`Outcome` is not an enum.** It carries the raw name and reports whether this build knows it.
  A Dart enum with no fallback case is exactly how the tolerance rule gets broken — it would look
  correct until a routine backend release adds a value.
- **A missing method becomes `FeatureNotSupported`**, never a raw error, so a caller cannot
  mistake "this backend is older" for "this failed".
- **Every reader tolerates a shape the backend did not promise.** An unfamiliar field is ignored;
  a missing one reads as empty. A client that dies on an unfamiliar reply dies on a routine
  release.

A stream ends *only* on a final reply. Ending any other way — a destroyed socket or a polite
close — is an error, because a stream that completes quietly is indistinguishable from one with
nothing to say, and that renders as a machine with no tasks on it.

Two ways a connection hangs, both met for real and both fixed:

- **`Socket.close()` completes only when the *peer* closes.** A daemon holding a stream open never
  will, so awaiting it waits for ever. `VarlinkConnection.close()` destroys instead — canceling a
  stream is an ordinary act, not an error.
- **`await for` cannot be interrupted while it waits.** A generator paused on one notices it has
  been canceled only when the next event arrives, so leaving a `Watch` or a `Tail` hung until the
  daemon happened to say something — on a quiet machine, for ever. `callMore` uses an explicit
  subscription with `onCancel` for exactly this reason. **Do not put `await for` back.**

**A single call has a deadline; a stream does not.** `VarlinkConnection.answerWithin` is 30 s, and
`GetInfo` gets 5 s because "is there a daemon on this socket" has to answer fast. A backend that
accepts the connection and then says nothing is a real state — met for real here — and without a
deadline the window sits on an empty frame saying it is connecting, with nothing to report and no
way out. **Do not put a deadline on a stream**: `Prompts` may legitimately have nothing to say for
hours, and a timeout there would report a working backend as a broken one.

## The frame

`lib/src/app/` holds what the interface knows — `FleetModel` (what is on the machine and what is
selected), `ShellModel` (what is open and where the keyboard is), `Settings` — and `lib/src/ui/`
draws it. Three things there are decisions, not accidents:

- **Every action is a `Command` in `commands.dart`, including the ones that cannot run now.** The
  finder and the keyboard read the same list, so a shortcut cannot come to mean something other
  than the entry naming it, and an action belonging to a screen that is not open is still
  findable. An unavailable command is listed **with its reason** — hiding it answers "there is no
  such action" when the truth is "not yet, and here is why".
- **The frame talks to `FleetBackend`, not to `SokarClient`.** Four members wide, and it exists so
  the frame can be judged when the backend refuses, has no `Watch`, or goes away — see the
  measurement under Tests. Anything that widens it is probably a screen reaching past the frame
  for something it should ask the client for directly.
- **Losing contact keeps the last task list.** Clearing it would draw a machine with nothing
  running on it, which is the one reading a dropped tunnel must never produce.

**`SOKAR_SOCKET` is read in one place: `Machine.local()`.** The rework that made several machines
possible quietly dropped it, so the window opened on the local runtime socket and said it could
not connect to a daemon nobody was running — with every test green, because nothing covered which
socket the interface picks. It takes an injectable environment now, and `test/app/machines_test`
is that guard.

**`Machines` has a machine from the moment it is constructed**, not from when `load()` finishes.
The frame is drawn before anything can be read back from disk, and a frame with no machine behind
it has nothing to draw — which it did not, as a null check on the first frame.

**Connected to every machine, acting on one.** `Machines` opens a `FleetModel` per configured
host and keeps them all open, because a clearance prompt has a deadline and is never asked twice —
a machine nobody is connected to is one whose blocked work expires unseen. The tree on the left
lists what needs a person, then every machine with its state, opening like an accordion onto
Running, New project and its projects, and the stop for every machine at its foot. Which machine
an action lands on is the machine whose place is open, named in its title — never whichever host
happens to be reachable. A tile on what needs a person selects its own machine before any of its
actions runs.

A host is a name and a socket path, and raising the forward is somebody else's job —
the managed tunnel is the interface doing it, and it must never become the
only way in. Running `ssh` would not breach the no-shelling-out rule, which is about never
re-implementing the *domain* through the CLI; `ssh` is transport.

**An action lives where it acts, and the finder goes there.** `Command.home` says where: the
machine's title or its menu, the selected project's header menu, New project in the tree, the
start tile, a saved job's tile, a work tile's menu, or the machine's status line. The finder goes there, marks
it and gives it the keyboard, so the next time it is found without the finder; only an action
with no single place runs from the finder at once. The menu bar holds what belongs to no machine —
Machines, Options, About — and nothing else. Every one of them still reads `commands.dart`, so a
shortcut cannot come to mean something other than the entry naming it.

**A machine's place, top to bottom.** Its title — how it is reached, the daemon's version, its
emergency stop and its menu. Under Running, the work running in every project; under a project,
that project's header — its state and its menu — and all of its work. Both end with a tile that
starts work, and a project with one per saved job. Its status line — the last thing said, and what
this session ran there. Opening a machine keeps the project chosen on it; Running is what widens
back. A new project is described in the machine's place and is the one chosen once it is made.
Whatever opens does so over the middle, with the title and the status line staying put.

**Closing the window asks first.** There is no Quit: the window's own close asks the app, the app
names what keeps running, and only then takes down the forwards it raised. Without that, `ssh`
children outlive the window.

**A pointer must be sufficient, not merely optional.** The rule was "every action is reachable from
the keyboard alone; a pointer is optional everywhere, never required" — and the first build of the
shell inverted it. Appearance, reconnect and quit were reachable *only* through the finder, so the
pointer was the impossible half. Every action now has a place a pointer can reach, and the
scenario *every action is reachable with a pointer alone* is the guard that should have caught it.

**Icons are outlined by default and filled only for a selected state** — `folder_outlined` in the
rail until that section is the one you are in, then `folder`. Taken from melkheftken, whose whole
interface runs on eighteen icons; a set that mixes the two weights reads as two interfaces. Pick
one that says what the thing *is*: a push waiting at the gate is `outbox_outlined`, because
`Approve` is the only call in the contract that sends anything anywhere.

**Nothing outside `lib/src/ui/tokens.dart` spells out a spacing, a width or a radius**, and
nothing outside `window_size.dart` compares a width. Layout asks named questions —
`showsTwoPanes`, `showsOpenedBeside`, `showsMenuBar` — against Material 3's own size classes
(600/840/1200). Numbers picked to make one screen fit are wrong the moment a second pane exists,
and there is no way to tell afterwards which of a dozen scattered comparisons meant the same
thing.

**What opens over the frame is a closed set, not a flag per screen.** `ShellModel.opened` is a
sealed `Opened` — nothing, work, the session record, one operation's output. Three booleans would
have been three states that contradict each other the first time two were true at once, and there
are already four things that open.

**A long operation is owned by `Operations`, never by the view showing it.** The subscription
lives in the session record, so closing the window onto a build does not stop the build and
arriving late does not mean having missed the output. That is the whole class: the operation record is the
machinery, and preparing an environment, backups and starting work are what use it.

**Derive nothing at this end that the far end already knows.** A task's logs are asked for, never
held as a set of names: which files exist depends on what the task started, so a client that knew
them would offer one that was never going to exist and would never show one a later release adds.
The same rule as a prompt's `key`, which is the daemon's derivation and not ours. When something
is missing, ask for the method — `Logs` was asked for and arrived the same day.

**ANSI color is honored, never printed and never stripped.** A log with the escapes left in is
unreadable; one with them stripped loses what the color was carrying. `ansi.dart` maps each
color to something from the theme with the same *meaning* — red to `error`, green to `primary` —
because a terminal's black is invisible on a dark background and its bright yellow is invisible on
a light one. Backgrounds are ignored on purpose: a log that paints its own cannot stay legible on
both, and the person chose the appearance.

**Following a log is a switch, not a scroll position.** Suspending stops the *view* moving and
never the reading, so the lines keep accumulating and resuming shows what arrived rather than a
gap. A view that stopped following because somebody scrolled up would be the same as having no
switch at all.

**The egress editor** — `Egress` and `SetEgress` landed 2026-09-07 and
carry five rules that are easy to get wrong and expensive to get wrong:

- **Preview, then write, and show the preview.** `dryRun: true` answers `PREVIEWED` with exactly
  the `opens` and `closes` a real call would make, having written nothing. It is the most
  consequential edit in the product, and applying it without showing the effect is worse than the
  file editor it replaces.
- **`opens` and `closes` are hosts, not set names** — adding one set opens eleven hosts, and
  whoever presses the button is entitled to see them. **The order is meaningful**: hosts arrive
  grouped by what granted them. Render in the order given; never sort.
- **`cost` is usually empty, and matters when it is not.** It is filled only when *this* change
  makes a forge reachable for a guarded project, and it is not repeated on later edits — a warning
  shown when nothing changed is one people learn to skip.
- **Every refusal is an outcome, not an exception**: `NO_SUCH_SET`, `REFUSED_BY_CLASS`,
  `UNREADABLE`, `NOT_WRITTEN` — and on `NOT_WRITTEN` the `opens`/`closes` still describe what it
  would have done.
- **Nothing here reaches a running task.** A container's ruleset is built when it starts, so a
  successful change says *"applies to the next task"*.

`Egress.hosts` is the whole composition a task run uses, the agent's own grants and its provider's
host included. `refused` is what an agent asks for and is deliberately not given — the distinction
a dropped packet cannot make between "we said no" and "nobody added it".

**One interface is in charge, and a second launch joins rather than competes.** Two of these watch
every configured machine, so every clearance question would be raised twice and answered from
whichever window somebody happened to see. A unix socket rather than a lock file, because the
second launch has something to say — *come forward* — and a lock file cannot be talked to. A
socket left by a run that died is taken over, not surrendered to: otherwise one crash means the
interface can never be opened again without somebody knowing to delete a file they have never
heard of.

**A restored selection is set without checking that it exists.** Restoring races the machine still
answering — `Projects` arrives before `List` does — so a check at that moment keeps whatever
happened to have loaded and silently drops the rest. `FleetModel` drops a selection that turns out
not to exist once it knows, which is the only moment it can be decided honestly. **A test that
"restarts" by keeping the models proves nothing**; `World.restartApp` builds them again, and that
is what caught this.

**Nothing changes a project's egress without having shown what it would do.** `dryRun` answers
exactly the hosts a real call would open and close, having written nothing, and the preview is
what somebody agrees to — the change is then asked for again *in the same words* rather than
remembered as a promise. Five things about it that are easy to get wrong:

- **`opens` and `closes` are hosts, never set names.** One set opens eleven, and whoever presses
  the button is entitled to see which. A guard that only counted them let a mutation through here
  once; it reads the rendered hosts now.
- **The order is the answer, so nothing sorts it.** The first grant wins, so the order says which
  source each host came from.
- **`cost` is usually empty and matters when it is not.** Filled only when *this* change makes a
  forge reachable for a guarded project, and never repeated later — a warning shown when nothing
  changed is one people learn to skip.
- **Every refusal is an outcome**: `NO_SUCH_SET`, `REFUSED_BY_CLASS`, `UNREADABLE`, `NOT_WRITTEN`
  — and on the last, `opens`/`closes` still say what it would have done.
- **Nothing here reaches a running task.** A container's ruleset is built when it starts, so a
  written change says *"applies to the next task"*. An `offline` project declares no egress at all
  and the action is not offered for one, rather than offered and refused.

**What is notified is decided in `Notifications`, and how it is raised is a seam.** The rules —
when to speak, what to say, what to stay quiet about — are the requirement; `notify-send` is not,
and a widget test asserts the rules against a recording notifier. Running `notify-send` is no
breach of the no-shelling-out rule: that rule is about never re-implementing the *domain* through
the `sokar` CLI, and this is the desktop.

- **Raised once per thing, never per event.** `Prompts` re-arrives whenever anything changes, so
  raising per event would say the same sentence until somebody turned the lot off.
- **A waiting decision is the only thing entitled to insist** — `critical`, because the watcher
  gives up on its own and a question queued politely behind everything else is one that expires.
- **Finishing is told apart from failing**, which the session can do for what it started. A *task*
  that ends cannot be: `activity` is `DEAD` for stopped, finished and killed alike, and `state` is
  prose that must not be parsed.
- **A desktop with no `notify-send` is said out loud** in the status line. Believing notifications
  are on when they are not is worse than knowing they are off, which is the whole requirement.
- **The per-project switch is visible on the project**, because a switch whose state cannot be seen
  is one people turn off twice and never back on.

**A task running with `clearance: "off"` is marked wherever it appears.** Nothing asks and
nothing is refused — the firewall is loaded and no decision is ever put to anybody. Somebody chose
that deliberately, and a run shown like any other hides the choice. `""` means a task older than
the field: render the absence, never guess `prompt`.

**Allowing says "this host is now reachable", never "the request that just failed will now
succeed".** Measured on the Sokar side: the packet that was dropped is gone, adding an element
affects the next attempt, and whether the work retries is the work's business. A widening by name
costs one dropped packet even when it is granted.

**A clearance decision is remembered per address, not per name, and survives the task being started again.** One fixed
address is asked about once for the whole run; a CDN or anything round-robin asks again for each
address it resolves to. The interface says so when it happens, because otherwise somebody
reasonably concludes their last answer was ignored.

**A clearance question is the one place where interface latency costs something real.** The task
is stopped while it waits and the watcher gives up on its own timeout, so `Prompts` is a stream,
never a poll — and it is watched **per machine, for as long as that machine is watched**, because
one nobody is connected to is exactly the one whose work expires unseen. The count sits on the
rail: "somebody must do something" cannot be a thing you find only by having looked in the right
place.

- **An answer is not applied optimistically.** The row stays until the stream confirms it. The
  answer is real when whatever asked has taken it, and a row that vanished on the press would
  claim something nobody had confirmed.
- **A client sees the echo of its own `Decide`** — matched by `task` + `key` and removed, which is
  idempotent, so applying it twice is impossible rather than merely avoided.
- **`NoClearance` is an answer**: the task stopped running, so nothing could be told. Said plainly,
  because an answer that went nowhere would leave somebody believing they had unblocked something.
- **An expired question is kept and marked.** Nothing asks about it again, so one that merely
  stopped arriving would be indistinguishable from one still waiting for its operator.

**`activity` sits beside `state`, never instead of it**, and `state` is still the runtime's own
words and still never parsed. Five values, and two of them are traps:

- **`UNKNOWN` must never be drawn as idle.** It is the *normal* answer for a task somebody
  attached a terminal to — the work goes to that terminal, not to anything the daemon reads. B11
  asked for a value that says "cannot see" precisely because a state that is silently wrong is
  worse than one that admits it, so spending it on "idle" throws away what was asked for.
- **`WAITING` is a signal, never a timeout.** Whatever asks the question writes it down and
  removes it when the answer comes. Quiet is `IDLE`. **Do not label `IDLE` as "probably waiting"**
  — today the signal covers clearance questions only, an agent asking its own question inside a
  session produces nothing Sokar can see, and guessing is the thing this field exists to avoid.

**"Idle for forty minutes" is arithmetic on `since`**, never a reading of `state`. `since` is
empty when the runtime cannot say — a container created and never started answers a zero time,
which renders as a date centuries out — and `howLong` answers null for that, and for a clock that
disagrees, which two machines and a forwarded socket make ordinary.

**A task older than these fields answers empty for all of them.** Render the absence; it is not an
error.

**Approving is the only thing this interface does that sends anything anywhere**, and the branch
is typed, never inferred — `Approve` requires one, and a push forwarded onto a guess is one nobody
decided about. Dropping a request sends nothing at all: the work stays in the mirror and only the
asking is gone, which the wording says out loud.

**A review is a diff, and that is the ceiling.** `Review` answers a unified diff and a log;
nothing reads a file at a revision, so what *surrounds* a hunk cannot be shown and a whole-file
view is not reachable. `diff.dart` turns the diff into a file tree with hunks, which is the honest
most that can be built — and **Copy the diff** is the way past it, because the common case is
somebody wanting it in the tool they review in. The parser is deliberately tolerant: this is git's
output, not a promise in the IDL, and refusing to render because a header was unfamiliar would be
worse than showing the lines it understood.

**A removal says how much it destroyed.** `Stop` returns `discarded` — how many paths the
container had that its image did not, which is what the agent installed *inside* it and which has
nowhere to arrive, unlike the workspace the gate holds. Nothing else records that any of it
existed, so a removal that does not mention it is the last chance to know, gone. It is a count and
never a list: a container that ran at all reports `/etc` and `/var` as changed, so only added
paths are counted and there is nothing behind the number to show.

**A failed run is no longer swept away.** A non-zero exit stops the container and leaves it in
place — workspace, logs and unpushed commits intact — so `List` carries more exited tasks than it
used to. They are resumable, and `Stop` with `purge` is what discards one. Nothing here may assume
that failed means gone.

**A refusal takes the place of whatever was open, and is not a dialog.** `Stop` answering
`HOLDS_WORK` is the product working: the pane says what is held, offers *push it to the mirror*,
*discard it* and *leave it alone* in those words, and leaving it alone is the plain button. There
is **no force button** — `force` exists only for `NOTHING_KNOWS`, where nothing can say what is
held, and it is labeled as removing without knowing. Rescue and purge differ by one parameter and
one of them destroys work, which is why the guard on them reads what went down the socket rather
than what the screen said.

**An action with no method behind it stays in the menu, named and unavailable, with the reason.**
Renaming work and recreating it from scratch both started out with nothing behind them. An
action that simply is not there reads as one nobody thought of; one that says *"the backend has no
method for renaming work"* reads as what it is. `workCommands` builds the row's own menu and the
menu bar's entries from one list, so neither can offer what the other forgot.

**`Projects` lists every project, not only the busy ones**, and gives both `tasks` and `running`
rather than leaving one to be inferred. A project with nothing running is the ordinary case —
between tasks, or after one was stopped and can still be started again, which keeps its workspace. A
list of only active projects would be empty on a machine with a dozen projects on it. Filtering to
a busy view is this end's job and must never be assumed of the other; the counts on a row are the
daemon's, because it assembles them from the gate mirrors, the tasks that exist and the recorded
project files, and knows about work this end may not have matched by name.

**Projects are asked for, never derived from the task list.** `Projects()` answers them, and a
project that has never run anything is exactly the one a derived list could not show. Its `file`
is the path every gate method and `Start` take — **pass it through unchanged, never build one, and
never offer a file picker**: over a forwarded socket there is no filesystem on that machine to
pick from. An empty `file` is a project that can be listed and not acted on, which the row says
rather than leaving to a refusal later. Nothing refreshes the list, so it is asked for again
beside the tasks.

Two interface traps already met:

- **An `InkWell` with both `onTap` and `onDoubleTap` holds every single tap back** until the
  double-tap timeout passes. Rows select on a single tap and open with Return or a named
  affordance; do not put double-tap on a row to open something.
- **A widget built eagerly outside the branch that shows it still runs its null checks.** A
  detail pane built before the `if` that needs it crashed the whole frame with nothing selected.
- **Widget tests run at 1280x800**, set on `tester.view` with `devicePixelRatio = 1`, not with
  `setSurfaceSize`. The surface is set in *physical* pixels, so the default ratio quietly turned a
  desktop window into a narrow one and every scenario judged the fallback layout without saying
  so. Twice: first as the 800x600 default, then again through the ratio.
- **`World.settle` pumps three frames, not two.** A theme change animates, and the frame that ends
  the animation is not the frame that draws its result.
- **`pumpAndSettle` never returns while a spinner is on screen.** A running operation shows a
  `CircularProgressIndicator`, which is an animation with no end. Steps use `World.settle` — one
  frame, then one long enough to carry a dialog transition — and any new step must too.

**`stdin.readLineSync()` blocks the whole isolate.** `tool/mock_daemon.dart` waits for RETURN and
also serves a socket; reading stdin synchronously made it accept connections and then answer
nothing at all, so the interface sat on "asking the backend what is here" for ever. It cost an
afternoon and is exactly what a wedged daemon looks like from outside — which is why
`MockDaemon.neverAnswers` now produces it on demand. Read stdin asynchronously in anything that
also serves.

## The mock backend

A small Dart program that binds a real unix socket and speaks real varlink. The app's own client
runs against it unchanged — the socket path is the only thing that differs, which is the same
property that makes a remote backend work.

**It is permanent test infrastructure, not scaffolding.** It produces the states a real daemon
cannot be made to produce on demand: `MethodNotFound` for the degradation rule, an unrecognized
`Outcome` for the tolerance rule, `GetInfo` advertising `Tasks2`, a stream cut mid-flight,
`HOLDS_WORK` without a task that genuinely holds commits, a four-minute build, a prompt with a
live deadline. Those are the hard requirements, and none of them is reachable against a real
backend.

- **Scenarios are named for the situation, not the requirement.** A finished requirement is
  deleted; the situation outlives it.
- **Events are driven by the test, never by wall clock**, or stream tests become flaky and flaky
  tests get deleted.
- **`pushes` for `Watch` and `Prompts`, `stream` for anything finite.** `stream` holds each event
  back until the next one arrives, because a finite stream has to know which reply is its last.
  Neither of those two is finite, and against a held-back stream every change reaches the
  interface one change late — which looks exactly like an interface ignoring its own events.
- **A client that leaves mid-write reports it on `Socket.done`, not from `add`.** Unhandled, that
  asynchronous error fails whatever test happens to be running. Canceling a stream is an ordinary
  act, so the mock absorbs it.
- **One CI job runs against a real daemon** and compares the mock's surface against
  `GetInterfaceDescription`. The mock proves the client handles what it is sent; that job proves
  the contract is what we think it is. **A drifted mock is worse than no mock.**
- Unix socket paths are limited to about 108 bytes on Linux, and test temp directories reach it.

## Analyzing and formatting

- **`dart analyze`, never `flutter analyze`.** The latter has been seen to rewrite
  `analysis_options.yaml` with an exclude block nobody wrote, silencing findings instead of
  fixing them. `dart analyze` must stay at **"No issues found!"**.
- **Never `dart format` the whole tree.** It reflows every file it touches, and a formatting pass
  over untouched files buries the actual change in a diff nobody can review. Format only the
  files you edited, by name.

## Building

```
flutter build linux --release
```

Measured 2026-09-07: **11 s, 22 MB**. The output is a bundle directory — the binary,
`lib/libapp.so` (AOT-compiled Dart), `lib/libflutter_linux_gtk.so`, `data/`.

The Linux desktop toolchain is `clang`, `cmake`, `ninja`, `pkg-config` and `libgtk-3-dev`.
`flutter doctor -v` reports whether they are all there.

**This repository never needs a JDK, and the backend never needs a Flutter SDK.** That
independence is the reason the two are split; do not introduce anything that breaks it.

## Deployment

Delivered as a `.deb` and an `.rpm`, the same as every other part of Sokar
([F26](requirements/F26-Linux-Packaging.md)).

- **Built with [nfpm](https://nfpm.goreleaser.com/)** — one static binary, one YAML, both
  formats. Deliberately *not* `rpm-maven-plugin` and jdeb, which is what the backend uses: they
  would put a JDK back into a build that has none, and need `rpmbuild` on a Debian runner. What
  must match the rest of Sokar is the package a person installs, not the tool that wrote it.
- **Dependencies are derived, never listed.** `dpkg-shlibdeps` and rpm's ELF scanner work out
  the GTK3 stack from the shipped `.so` themselves. A hand-written list goes stale between
  Flutter releases.
- **`Recommends: sokar`, not `Depends:`.** An interface pointed at a remote daemon over SSH is
  useful with no local backend at all.
- **Publish into the same repository as `sokar`** and the agent packages. A dependency between
  packages does not resolve when they are split across configured sources — recorded in the
  backend's `AGENT.md` and true here unchanged.
- **Build on Ubuntu, never Fedora.** The bundle links glibc dynamically, and the backend already
  learned this the expensive way. Flutter adds a dimension the CLI never had: the bundle links
  the GTK3 stack too, so **the build machine's GTK is the oldest GTK the package can run
  against.** Build on the oldest distribution that must be supported, not the newest available.
- **No cross-compile.** Flutter has none for Linux desktop, so every architecture shipped needs
  a builder of that architecture. This is the open question on arm64, which matters because
  Sokar runs on a Pi.

## Security rules that are not negotiable

- **No secret is ever displayed or logged.** The `Credentials` call returns names, types and
  lengths — never a value, by design. Nothing here should ever want more than that.
- **Nothing authenticates.** The socket is owner-only, so the filesystem decides who may
  connect; a remote backend is an SSH forward, so its authentication is SSH's. **If a design
  starts needing a token, a session or a login screen, something has gone wrong upstream of
  it** — say so rather than building one.
- **Do not weaken a refusal to make a flow smoother.** If `Stop` says `HOLDS_WORK`, the
  interface's job is to show what is held and make the choice legible — never to add a "force"
  that quietly discards it.

## Requirements

- Files are `requirements/FNN-Name.md`. **The number is identity, not order**; the table in
  [requirements/README.md](requirements/README.md) is the order.
- **A finished requirement is deleted**, file and index row together. What it measured — the
  expensive facts and the traps — moves into this file, and one line summarizing it into the
  index's *"What was here and is finished"*. The set is what is left to do, not a history of what
  was done; the history is in git.
- **Its scenarios stay.** They are the guards that keep the finished thing working, and retiring a
  requirement must never quietly delete its tests — so the id outlives the file, listed in
  `retired` in `test/requirements_coverage_test.dart`, and the traceability report reads the same
  as it always did. `retired` and `pending` may not overlap, which a test asserts.
- A file ending in **To be checked** has something unresolved that could change what it
  promises, and its index row is marked as an open question.

## Commits

One brief line. The reasoning behind a change is a finding, and a finding goes in this file
where it can be found later without `git log`.

## Raising a window is the desktop's business

Dart cannot present a window; nothing in `dart:ui` or `dart:io` reaches the window manager. The
Linux runner carries a `sokar/window` channel with one method, `present`, calling
`gtk_window_present_with_time`, and `Window.comeForward()` is the whole Dart side of it. It is
quiet when it fails — a desktop that will not raise a window, or a host that has none, is not
something to report to somebody who is looking at another window anyway.

A second launch exits before Flutter's debugger attaches, so `flutter run` reports
*"Error connecting to the service protocol"* for it. That is the tooling, not the interface: the
running window did come forward. Anything that exits early from `main` will read the same way, so
say what happened on stderr first — a launch that simply vanishes reads as one that crashed.

## The mock daemon does not stop when its stdin closes

It reads keys, and a closed stdin is not a key. So `( sleep 20 | dart tool/mock_daemon.dart ) &`
leaves the mock running after the pipe ends, and the shell that started it waits on it forever.
Seven such shells accumulated over one session, each holding an idle Dart VM.

Give it a deadline of its own — `timeout 20 dart tool/mock_daemon.dart` — rather than expecting a
closing pipe to end it, and kill it by pid when a script is finished with it.

## Widening a running task is not the egress editor

`SetEgress` edits a file the **next** task reads. `WidenTask` reaches the container in front of
somebody. They look alike and three things separate them, all of them load-bearing:

- **`scope` is required and the daemon will not pick one.** Omitting it answers `ScopeRequired`.
  "This run needs it" and "this project needs it" are different intentions, so the screen offers
  them as two choices with **nothing preselected** — a default here would make somebody's decision
  for them. `Scope.run` does not survive a stop: a container started again rebuilds its ruleset and
  its resolver from what is on disk, and a run-only grant is not on disk.
- **`NO_PROJECT_FILE` is a partial success, not a failure.** The run *was* widened; only the file
  was not written, because nothing knows where the file is. Rendering it as an error tells
  somebody the task still cannot reach the host when it can — wrong in the expensive direction.
  `WidenOutcome.reached` says so and `failedOutright` deliberately excludes it.
- **Say "reachable from the next attempt", never "the request that failed will now go through".**
  The refused connection was dropped at the packet level and is gone; whether the agent retries is
  the agent's business. Same truth as `Decide`, and the sentence most likely to be got wrong.

Underneath, the resolver is told without restarting — the granted names go in a file dnsmasq
re-reads on `SIGHUP` — and the firewall is **not** told. The clearance watcher recognizes the name
on the first connection and allows it without asking. So a widening may be followed by one dropped
connection in the prompt stream with no question attached. That is the mechanism working, not a
race, and nothing in the interface should treat it as one.

`REFUSED_BY_CLASS` and `NOT_RUNNING` are both predictable from `Task`, so the action is offered as
unavailable with the reason. There is **no narrowing and no granting of sets**: neither is decided
on the backend, and a control for either would be a screen with no method behind it.

## A prompt makes `Start` run the agent

`Start` without a prompt brings the container up and returns. **With a prompt it runs the agent**,
so the call lasts as long as the run — minutes, sometimes tens of them. Four things follow:

- **It streams, and nothing may put a deadline on it.** `callMore` has none, deliberately, and
  that must stay true. A timeout would not stop the agent anyway: the run carries on in the
  container and the interface has merely stopped watching, which is a different thing to tell
  somebody than "canceled".
- **Read `exitCode` in four bands, not two.** `0` finished; `124` hit its own time limit and was
  killed, **and the log is kept** — show what it managed to do; `69` the run was **refused before
  anything was created** — no container, no workspace, nothing to clear up, and no log to offer;
  anything else is the agent's own code. `OperationFailed` carries all four, with `leftALog` and
  `ranOutOfTime` for the two that are not ordinary failures.
- **`69` does not mean one thing, so never name its reason.** It started as *no agent installed*
  and now also carries *an unattended run whose credential could not be read*. The daemon prints
  which; a client that spelled one of them out would be wrong precisely when somebody believed it.
  This is the band standing in for an outcome vocabulary `Start` does not have — shape 3 is where
  that arrives.
- **What streams is the raw log**, the same text `Tail` serves for `task.log`. The formatted view
  an agent can produce is made in the CLI process and is not on the wire. Asking for one needs a
  method that does not exist.
- **`mode` is never assumed.** `Start` defaults it — `UNATTENDED` with a prompt, `SHELL` without —
  and the screen does not rely on that, because the mode says whether anybody is going to be
  there. `SHELL` *with* a prompt is accepted and recorded, which would describe a run nobody is
  attached to as one somebody is driving: the prompt box belongs to `UNATTENDED` alone.

**Ask when a summary and its own IDL block disagree.** The note announcing this left `mode` out of
the block while its closing sentence assumed it. Three readings were possible and they led to
different screens; asking cost an hour, and building the wrong one would have cost a rebuild. The
same question turned up a real bug — `Task.mode` was going out in lower case against an IDL that
declared the `Mode` type — which cost this build nothing, because it compares against the
contract's spelling and not against what happened to arrive.

## What the daemon's own measurements corrected, 2026-09-07

Four things this build assumed, or was told, that turned out not to hold. All four came back from
the Sokar side after being measured against running code rather than recalled.

- **`VaultState.readable` was wrong, and is now right.** It claimed to separate a locked vault
  from an empty one and did not: an unlocked, empty vault answered `false`, exactly as a locked
  one did, because the field was inferred from an empty credential map and the map was empty for
  three different reasons. Fixed on the Sokar side in `758969f` — an unlocked vault holding
  nothing now answers `true`, a vault that does not exist yet is readable and empty. Nothing here
  consumed it, so the fix landed **before the first consumer**, which is the only comfortable time
  for a defect like that. The rule that made it free: this build had not yet built a screen on a
  field whose meaning it had not seen measured.
- **`Start(dryRun:)` is not a rehearsal.** It reports what the project file opens and returns —
  before the runtime check, before the hooks check, and before anything touches the vault. The
  action behind it used to say *"Check that work can start here"*, which claimed something it
  never did; it now says *"Show what this project would open"* and passes the project file, which
  it previously did not.
- **`Start`'s IDL comments about defaults were false.** They said `agent` and `provider` both
  default to *"the project's own"*. A project can name neither: `Project` has no such field and
  `project.yml` has no such key. The real defaults are the only agent installed — or a refusal
  naming all of them — and the agent's own declared provider. Cost this build nothing, because
  nothing here restated a backend default; **restating one is how it would have.**
- **Which credential a run needs is a function of four things**, not of the agent: the agent's
  declaration, the installed providers, the run's `provider` override, and *what the vault already
  holds* — an older vault answers under the agent's name rather than the provider's. So a client
  cannot assemble the answer from parts it has, which is why a method answers the whole
  question.

## An explicit list of egress sets is a guarantee, not a missing feature

`SetEgress` takes named sets. There is no way to say "all sets, including ones installed later",
and that is deliberate on the Sokar side: an open-ended selection means a set shipped in a later
release silently widens a project nobody edited. The operator approved *"everything that exists"*,
and what exists changed underneath them.

So where the interface cannot offer it, it says **why** — not merely that it is unavailable. This
was recorded as a contract gap for a while and it was never one.

## Starting without a credential is not a clean failure

Measured on the Sokar side, 2026-09-07: a missing credential does **not** stop a launch. It prints
one line and starts the task anyway with no broker wired up; the agent then fails to authenticate
from inside the container. What somebody is left with is a container that came up, a workspace,
and — once an unattended run fails — a held, stopped container that nothing removes, because a
failed run is kept on purpose.

So when the credential check lands, the action stays offered and the sentence is **"this will
start a container you will have to clear up"**, naming the workspace and the held container. Not
*"this may fail"*: a hedge is not something somebody can decide with, and this was going to be one
until it was measured.

## Check the fields, not the method name — twice now

A requirement is covered when every acceptance criterion has something behind it, not when the
obvious method exists. This has now been got wrong twice on the same map:

- **Starting work**, because `Start` exists and starting is one call. The call had no parameter for two
  thirds of what the requirement asked for.
- **The agent inventory**, because `Agents` exists and answers a list. Two of its four criteria — the pinned build
  and its digest, and which copy of a shadowed name is in use — have no field behind them.
- **F15**, because `Lock` landed and the row was changed to *"nothing missing"* on the strength of
  it. `Lock` answers half of one criterion out of seven: there is no `Unlock` (by design), nothing
  says how an unlocking is remembered, nothing reveals a recovery secret, and nothing changes a
  passphrase. **A method arriving is not a requirement being answered, even when it is the method
  that was asked for.**

The pattern is structural, not careless: the gap map is written from method names and the
requirements are written from what a person sees. **Walk a requirement criterion by criterion
against the reply type before writing anything down as ready.**

## A template carries a job, never a permission

`Start` takes `clearance` and `noGate`. Either of them on a saved template would let a job set up
last month be running today with the gate off — and nobody re-reads a template before running it,
which is the whole point of having one.

So `Template` has five fields: name, project, agent, mode, prompt. Reading one **names its fields
rather than copying the stored map**, so a hand-written `noGate` in the settings file — which is
plain JSON somebody can edit — never reaches `Start`. A mode this build does not recognize makes a
job unstartable rather than starting something nobody here can describe.

The project's own security class is out of reach for a different reason and a better one: `Start`
has no parameter that sets it. That half of the requirement is answered by the contract.

**Templates follow the person, not the project.** A project file describes constraints, not
instructions, so they live in this interface's settings — the operator's answer when sharing them
with the project was asked for.

## A fixture edited to fit a feature will hide the feature being wrong

The rule that a stand-in must not describe what the contract cannot deliver was already here. It
was broken anyway, in the direction the rule does not obviously cover: not by a fixture drifting,
but by **a fixture being edited on purpose so that a feature would have something to show.**

`Agents` answers one entry per name — they are keyed by name on the daemon side. The agent
inventory was built to detect two entries sharing a name and to say it could not tell which one
ran; the mock and the fake were given a duplicate so the view had something to render, and six
scenarios passed. The state cannot occur.

**When a feature needs a fixture changed before it has anything to show, that is the moment to
check the contract, not the moment to change the fixture.** Shadowing is real, is resolved before
anything is listed, and which copy lost is a reply field that does not exist yet.

## Packaging

`tool/package.sh` builds a `.deb` and an `.rpm` with [nfpm](https://nfpm.goreleaser.com/), which is
one static binary reading one YAML. Not Maven: the backend stamps its packages with
`rpm-maven-plugin` and jdeb, and using it here would put a JDK back into a build that deliberately
has none. What has to match the rest of Sokar is the package somebody installs, not the tool that
wrote it.

Four things measured on 2026-09-07 that are easy to get wrong and quiet when wrong:

- **`type: tree`, or the bundle is flattened.** A plain `src`/`dst` pair puts `libapp.so` and
  `icudtl.dat` beside the launcher instead of under `lib/` and `data/`. The package installs
  cleanly and the application then opens no window.
- **`dpkg-shlibdeps` needs a staged package tree.** `libflutter_linux_gtk.so` has an RPATH of
  `$ORIGIN`, which it can only resolve against a tree with a `DEBIAN/` directory. Pointed at the
  build directory it warns and analyses less than it should.
- **Dependencies are derived, never written.** `dpkg-shlibdeps` for the Debian side, with version
  floors; sonames straight out of the ELF for rpm, because nfpm does not run rpm's scanner. Both
  derivations refuse to produce an empty list rather than shipping a package that installs
  anywhere and runs nowhere.
- **`recommends: sokar`, never `depends`.** An interface pointed at a remote daemon over a
  forwarded socket is useful with no local backend, and a hard dependency would put one on a
  laptop that never needed it.

`amd64` only. Flutter has no cross-compile for Linux desktop, so arm64 needs an arm64 builder;
claiming the architecture without one would produce a package that installs on a Pi and cannot run.

`test/packaging_test.dart` holds all of this without building anything. **Assert against the
template with comments stripped** — every rule is also explained in that file, so a plain
`contains` matches the sentence describing a directive as readily as the directive. The first
version passed with the bundle flattened.

## An agent says what it pins, what it refuses, and what it fetches

Three shapes worth knowing before rendering any of them, all measured on 2026-09-07:

- **`Agent.version` is the build it pins**, read from the agent's own manifest. Nothing executes
  an agent to ask. The contract's own comment said otherwise for a while, and that wrong comment
  put a wrong entry in the gap map — **a description in the IDL is as load-bearing as the type.**
- **A digest is per artifact, and has exactly two states.** Verified, or `unverified` with a
  stated `reason`; the daemon's constructor refuses one with neither, so a blank digest with no
  explanation cannot arrive. Show the reason, not a warning icon: an artifact knowingly fetched
  without a digest is a decision somebody made. An agent with **no artifacts at all** is a third
  honest answer about the agent — it writes its tool into the image — not a fourth state.
- **Shadowing is a list, never a flag.** A binary shadowed by a copy in a more specific directory
  is never started, so it has no `Agent` entry to mark; the losers come back separately, each
  naming the copy that runs instead. *"Not in use"* on its own leaves somebody asking where to
  look.

## Forwards this interface raises

`ssh -L <local>:<remote> <host> -N`, one process per machine, in `lib/src/app/tunnel.dart`.
Running `ssh` is not a breach of the rule against shelling out: that rule is about never building
a second implementation of the *domain* by parsing the `sokar` CLI. `ssh` is transport.

- **`BatchMode=yes`, always.** A passphrase and an unknown host key are terminal prompts, and this
  has no terminal. Batch mode makes `ssh` fail instead, and its sentence is what gets shown —
  *"Host key verification failed"* is a different problem from a machine that is not there, and
  reporting the second sends somebody looking in the wrong place.
- **`ExitOnForwardFailure=yes`**, or `ssh` stays up with nothing bound under it, which reads as
  connected.
- **`ssh` can exit before a stderr subscription has delivered anything.** Collect it as one
  future and await it before composing the message. The first version reported *"exit code 255"*
  with the useful sentence still in the pipe.
- **Wait for a socket, not for a file.** Anything at that path would otherwise read as a working
  forward, and a leftover from a run that died is exactly a file at that path.
- **Only what was raised here is ever taken down.** A machine described by a socket somebody else
  forwarded is not in `Tunnels`' map at all, which is what makes that criterion true rather than
  remembered.

**Frame tests do not spawn processes.** `FakeTunnels` in the World records what was asked for and
answers; the process itself is proven in `test/app/tunnel_test.dart` against real sockets. Same
reason `FleetBackend` is a seam: a widget test's clock does not carry real input and output.

## Break it and watch the *right* thing fail

Mutation testing is the rule here already: after writing a guard, break what it guards and watch it
fail. That is not enough on its own, and the Sokar side produced the sharpest case of why on
2026-09-07.

Their check for which copy of a shadowed agent runs read the *message* the system printed. They
mutated the rule to pick the wrong copy — **and the check still passed**, because the message was
built from the losing side and stayed word-for-word identical while the register held the other
one. It was asserting what the system said about itself, and the system was saying something
false. The corrected check reads which binary actually runs, and failed instantly.

**A check that reads a report is testing the reporter.** Three of the near-misses on this project
share that shape: a grep matching the fixture's own name, a test for a state a constructor
forbids, and — here — two `contains` assertions that matched the comment explaining a directive
rather than the directive. When a mutation survives, the first question is not *"is the mutation
too weak"* but *"is my check reading the thing, or reading something the thing says about
itself"*.

**And a scenario can pass for the wrong reason**, which is the other half of the same lesson.
The scenario *"work that is not running has no session"* was written against a stopped **unattended** run
— so the agent rule took the action away, and deleting the running check changed nothing. The
mutation survived and the scenario looked fine. Two fixes, both worth copying: measure a rule
against work where **nothing else can produce the same outcome**, and assert **which** reason was
given rather than that there was one. A refusal has a sentence; check the sentence.

## The build that publishes

`.github/workflows/build.yml`, on push to `main` and on `workflow_dispatch`. Three jobs: test and
package, prove the packages install in clean Debian and Fedora containers, then publish. The shape
is the backend's, deliberately.

Four things in it exist because something failed silently, on their side or ours:

- **`--target-props="deb.distribution=snapshots;deb.component=main;deb.architecture=amd64"`.**
  Without them Artifactory **stores the file and never indexes it**: `apt` sees nothing and no
  error appears anywhere. Setting properties needs **Annotate** permission as well as Deploy, and
  **without Annotate the upload still succeeds and the properties are dropped** — which is what
  `artifactory-probe.yml` is for. Run it before trusting a first publish.
- **`--flat=true`**, or the source directory travels and the package lands where nothing reads it.
- **`ubuntu-22.04` on every job.** The bundle links the system GTK3 stack, so the build machine
  sets the floor; built on 24.04 the package refuses to install on 22.04, and the failure arrives
  at somebody else's `apt`. Raising it is a decision about who can no longer install.
- **One list of what was built**, written by the build and checked by the publish. The backend had
  two lists drift, and the symptom was a publish failing after the tests had already passed.

`secrets.JF_ACCESS_TOKEN` and `vars.JF_URL` — those exact names, not invented ones. Artifactory
signs the repository **index**, not the packages, which is why the Fedora repo file sets
`gpgcheck=0` and says so.

Publishing goes to the **`snapshots`** distribution. That word is in the line a person configures,
so a stable release will be a different word in the same repository rather than a new repository.

## A project's counts go stale on a push, and nothing said so

There is no `WatchProjects`. `Projects` answers how much work a project has, how much is running
and how much waits at the gate — all of it the daemon's arithmetic — and a task starting elsewhere
changes every one of those numbers.

`Watch` is the only signal that work moved, so **it is also the signal that those counts are
stale**. Until 2026-09-08 the task list updated on a push and the row above it did not: the work
pane and the project row disagreed, on screen, about the same machine. `FleetModel` now re-asks
`Projects` on every push, one read at a time — overlapping reads answer out of order and leave the
older one on screen.

## `behind` is a number; `behindReason` is whether it means anything

`Project.behind` is **meaningless unless `behindReason` is `MEASURED`**. Every other reason —
`NEVER_CHECKED`, `NO_UPSTREAM`, `OFFLINE`, `FAILED` — reports zero, and zero drawn without its
reason reads as *up to date*. A daemon reporting a failure may also leave the previous count in the
field, so a non-zero number with another reason is possible and must not be shown as a measurement.

**The age is part of the sentence, not a detail under it.** It is measured on the daemon's own
timer and never on the listing path, so the number is as old as the last tick. *"3 behind, as of 20
minutes ago"* is a fact somebody can judge; *"3 behind"* is one they have to assume is current.

## A snapshot version has to supersede the last one

Every build of `main` replaces the packages in a distribution called `snapshots`. With a flat
version — `0.1.0`, or `0.1.0~SNAPSHOT` — **`apt upgrade` has nothing to do**, and nobody ever moves
off the build they first installed. A snapshot repository whose packages never update anybody.

`0.1.0~snapshot.<run>`, from `SNAPSHOT_RUN` (CI passes `github.run_number`; a local build gets 0).
The same shape the backend publishes, so both sets sort the same way in one repository — separate
counters, because a package only has to supersede its own predecessor.

**Measured, not reasoned about**, with `dpkg --compare-versions` and `rpm.vercmp` on 2026-09-08:

| | |
|---|---|
| `0.1.0~snapshot.9` < `0.1.0~snapshot.10` | both formats compare digit runs **numerically** |
| `0.1.0~snapshot.999` < `0.1.0` | the whole series stays below the release |
| `0.1.0` **>** `0.1.0~snapshot.1` | a flat release version outranks every snapshot |

The last line is the trap in our own history: the first published build was a flat `0.1.0`, so
**nothing in the new series can supersede it** and an installation of it stays where it is. That
one artifact has to be deleted from Artifactory or it strands whoever installed it.

`tool/package.sh` refuses a flat snapshot and asks `dpkg` — on the version it actually built — that
the next build sorts above it and that 10 beats 9. Lexical comparison would have worked for nine
builds and then stopped quietly.

## An upload that succeeded is not a package anybody can install

Artifactory indexes asynchronously, and **a missing index, an empty index and a late index look
identical from a client.** Measured on 2026-09-08 while both repositories were empty, the Debian
index answered three different ways in twelve minutes:

| | |
|---|---|
| 404 | nothing there |
| 200, `Packages` empty (`d41d8cd…`) | a valid, empty index — `apt update` **succeeds** and finds nothing |
| 404 again | it settled |

None of the three was wrong, and a single probe of any of them is a coin toss rather than a
measurement. **Probe with a retry or do not probe.** The publish job waits up to two minutes —
twenty attempts, six seconds apart — for the `Packages` file to carry the exact `Version` field
from the built `.deb`, and for the rpm `primary.xml` to name the package, before it believes the
upload. It fails with *"uploaded but not indexed"* rather than reporting success.

This is the other half of the `--target-props` lesson. That the properties are *passed* is asserted
by a test on the workflow; that the package is *indexed* can only be seen from outside, afterwards.
The first is cheap and the second is the one that matters.

**`JF_URL` is the platform url, not the Artifactory base.** `https://…jfrog.io`, and the `jf` CLI
appends `/artifactory` itself. Raw `curl` does not, so anything built by hand has to add it —
normalise both ways rather than assume which shape the variable holds.

**And a check that fails must report what it asked, never a cause.** This step failed two green
publishes before it was right, and the second failure is the lesson. The first said *"check that
the token has Annotate as well as Deploy"* — a confident diagnosis, and wrong. The fix printed the
URLs and the HTTP codes; the next run then said

```
looking for 0.1.0~snapshot.5
  https://fuinorg.jfrog.io/sokar-dist-deb/…/Packages
  deb index: HTTP 404
```

and the cause was visible in one line: `/artifactory` was missing. **The second diagnosis — a
doubled slash — was also wrong**, and was written into this file as fact before it had been
measured. What made the third attempt a thirty-second job was not a better guess; it was that the
check had stopped guessing. **A wrong diagnosis is worse than no diagnosis**: it sends the next
person to look at permissions, and it gets written down.

## Panic stops and never removes

`Panic` stops every running task and its helpers at once. **Nothing is removed** — every
workspace, log and commit that never reached the gate survives, and `Start` brings a task back
with the work it had. An interface that presented this as a cleanup would send somebody looking
for work that is exactly where they left it, on the worst afternoon of their week.

So the screen says **what survived**, not what was cleared away, and it says it before the button
as well as after: somebody hesitating over an emergency stop needs to know it is recoverable more
than they need to know what it costs.

- **`surviving` is named, never counted.** Those helpers outlived their stop and have to be killed
  on the machine by hand; a number is not something anybody can act on.
- **It never acts on the first press.** `dryRun` says what would be stopped; agreeing is separate.
  **Leaving is the default and holds the focus** — the button that acts is the plainer of the two.
- **It lives on the status line**, which is on every screen, and keeps its button on a compact
  window even when the label goes. An emergency stop that falls off the edge of a narrow window is
  missing exactly when somebody reaches for it.
- **A task that was already stopped is absent from the answer**, not listed. So the sentence is
  *"stopped the 3 that were running"* and never *"stopped 3 of 7"*: this call never saw the other
  four, and somebody reading *"of 7"* goes looking for what happened to them.
- **A dry run's empty `surviving` means nothing was attempted**, not that nothing would survive.
  Rendering it as *"everything will stop cleanly"* would be a promise made out of an absence of
  evidence.
- **`PanickedTask.name` is what `Start` takes**, so the row that says what was stopped is also
  the row that says how to bring it back.

## Whether work can start is asked, never worked out

`CanStart` answers it before anything is created. **Do not assemble it here.** Which credential a
run needs turns on four things — the agent's declaration, the installed providers, the run's own
`provider` override, and *what the vault already holds*, because a vault written before the
provider-keyed change answers under the agent's own name. A client has one of the four.

`credential` in the reply is **the key that was actually looked for**, not the one that ought to
apply. Naming the other reports a key missing from a vault that has it.

Three of the eleven outcomes are three different actions, and they must never share a sentence:

| | |
|---|---|
| `NO_PROVIDER_CHOSEN` | choose a provider — *a provider, not a secret* |
| `CREDENTIAL_MISSING` | store a secret, named by `credential` |
| `VAULT_LOCKED` | unlock **at the machine** — a daemon has no terminal for a passphrase |

**Asked when the dialog opens and again when the agent changes, never cached.** What it answers
turns on what the vault holds, and that changes without anything else changing.

An unattended run that is not ready is **not offered**: the daemon refuses it before creating
anything, so the button says so rather than letting somebody find out. Interactive modes are
offered with the cost stated — a missing credential does not stop a launch, and a failed run is
kept, so what is left is a container and a workspace to clear up by hand.

## A range replace between two anchors deletes everything in between

`doc/Contract-Gaps.md` lost five requirements' worth of reasoning
to one edit meant to replace a single bullet. The shape was `text[:start] + new + text[end:]` with
`end` found by searching for the *next* heading, and everything between the two anchors went with
it. Nothing failed, nothing was reported, and it was found a day later while trying to edit a
bullet that was no longer there.

**Replace an exact block, never a range between two landmarks**, and when a range really is what
is meant, count what is inside it first. Recovered from git; the same edit had been made three
times before anybody noticed.

## The protected store: what happens here, and what happens at the machine

`Credentials` answers **names, kinds and lengths and never a value** — that is the whole promise of
the method, on a socket that can be forwarded over ssh. Nothing here asks for more, and nothing
about the store goes into the session record.

- **There is no `Unlock`, and there never will be.** A daemon has no terminal to take a passphrase
  at, so it can shut the store and can never open it. That is the design. Say it **beside the
  button that shuts it**, which is where somebody looks for the one that opens it — at the bottom
  of a pane it is an explanation nobody reaches.
- **`Lock`'s `holding` goes in the same breath as "shut."** A running task's credential proxy read
  the secret when it started and holds it where locking cannot reach; reporting the store closed
  without that claims more than happened.
- **`wasCached: false` means it was already shut.** Saying *"the store is shut"* for both is
  claiming to have done something that did not happen.
- **A shut store and an empty one both answer with no names.** They must never be shown the same
  way. (`readable` was wrong about this until 2026-09-07 and is now right.)
- **Changing a passphrase and bounding an unlock both happen at the machine** — `sokar vault
  passphrase` and `sokar vault unlock --for 30m`. Neither is a method and neither will be: both
  take a passphrase, and a daemon has no terminal. A bounded unlock has **no default**, so a
  locked store stays something somebody did rather than something that happened.
- **A bound running out makes `VAULT_LOCKED` ordinary.** The sentence the start dialog shows for
  it was written for a rare case and is about to carry real traffic; it says *unlock it at the
  machine*, which is true whether the store was shut by hand or by a timer.

**Two parts asking at once must never leave a stale answer over a newer one.** Every question is
stamped and an answer that arrives after a newer question is dropped. This failure is invisible —
both are answers — so it is driven by a scenario that races a slow read against a fast one rather
than trusted to review.

## A caption is not a name

`Task.name` is the identity: what `Start`, `Stop`, `Remove` and `Tail` are given, and what the gate ref, the
workspace and the log files are built from. `Task.label` is a caption somebody set, and **empty is
the ordinary state** — every task has none until a person types one.

Task control asked for work to be *renamed*. Renaming would move a gate ref with unreviewed pushes behind
it, which is nobody's intention when they rename a row in a list of forty. `Label` is what it
wanted:

- **The caption stands in front of the name, never in place of it.** In a list it is the heading
  and the real name moves down a line; in the detail the identity gets its own field the moment a
  caption exists. A caption that hid the name would make this interface and `sokar` on the machine
  disagree about what a thing is called.
- **An empty caption clears it**, rather than storing spaces under a name.
- The dialog says *"its name stays …"* before the box, because that is the question a person has
  when they are about to type one.

## Words this product uses

From the Sokar glossary, and worth keeping straight because two of them collide with ordinary
usage:

- **Node** — **an OS user with a `sokard`, not a machine.** Corrected on 2026-09-08; this file
  said *"a machine running `sokard`"* and that was wrong in a way this interface could have built
  against. The vault, the socket, the keyring, rootless container storage and the hooks path are
  all per user, and the firewall is narrower still — the ruleset lives inside each container's own
  network namespace.

  **So one hostname can be two nodes**: two developers with their own accounts on one machine have
  two vaults whose credentials never meet. **A machine list keyed by hostname would merge two
  people's work.** What identifies a node is how it is reached, which names the user as well as
  the machine — which is why `Machine.host` holds an ssh destination and why nothing here keys
  anything by hostname alone. (Two people *sharing* one account are one node and one vault, and
  unlocking it for either unlocks it for both. Nothing can detect that.)

  **There is no cluster**: no membership, no discovery, no daemon-to-daemon protocol, and a node
  does not know other nodes exist. The only thing that spans them is a client holding one ssh
  connection each, and it decides nothing. *"Which nodes are there"* is answered by configuration,
  never by the wire, and `GetInfo` gives a vendor and a version but no identity.
- **Host** — a destination in an egress set (`EgressHost`, `upstreamHost`). **Never a machine.**
  `Machine.host` here holds an ssh destination, which is ssh's own noun and appears verbatim in
  `ssh -L … user@host`; nothing on screen calls a machine a host.
- The egress set granting npm and the Node.js runtime is **`nodejs`**, renamed from `node` on
  2026-09-08. A project file still saying `sets: [node]` is **refused with the set name**, not
  ignored — which is the good failure, and why the rename happened before there was a release.

## Recreating is two calls, and the first can refuse

Recreating work is `Stop` then `Start` — no method missing. It exists for one reason and the dialog
says it: **a task keeps the image it started with**, so picking up a newly built environment means
being created again rather than started again.

**Nothing is started after a refused stop.** `Stop` answers `HOLDS_WORK` for a task holding commits
that never reached the gate, and starting anyway would leave two containers and lose the reason
the first one refused. The refusal is rendered where a stop's refusal is already rendered.

The launch is given the **same name, agent, mode and prompt**: recreating is meant to change the
environment and nothing else, and a launch without the name would put a second piece of work beside
the first rather than replacing it.


## A session is a pty, and varlink was measured before it was ruled out

Attaching to running work is **not a method**, and that was settled against the protocol rather
than argued: varlink is one call in and many replies out. `more` streams replies *from* the
service; there is no message a client sends into a call that is already open. A keystroke per call
was considered and rejected — calls are independent, so nothing orders two of them.

What carries a session is a **pty running `sokar task attach <task>`** — through `ssh -t` for a
machine reached over one, directly for a machine whose socket is here. Sokar's own verb, never
`podman exec`: this end never learns which container runtime is underneath, and the daemon can
still refuse before it execs and record that somebody was inside.

**Running that CLI is not a breach of the rule against shelling out, and the line matters.** The
vault refuses `sokar vault lock` because that would be a *substitute for a method the contract
deliberately does not offer*. Here the contract **cannot** carry it, and the Sokar side named the
verb as the way in. A method that exists and is not offered stays off limits.

**A consequence was written down here and it was wrong**, so it is corrected rather than deleted:
*"a pty on the node runs anything the operator can, `sokar vault unlock` included"*. It does not.
`task attach` execs `podman exec --interactive --tty <container> tmux …` — the far end is a
terminal **in the container**, under the same egress ruleset, clearance watcher and gate as
everything else in there, and the `sokar` binary is not in that image at all. Read off
`Podman.attachArguments` and `Containerfile` rather than taken from the correction.

What survives is smaller and belongs to the client, not to this feature: **this interface holds an
ssh connection and can open channels on the node**, and has since the forward existed. Never warn
that a session hands somebody the node. It hands them the container, which is what they asked for.

**The scrollback is 10,000 lines, and the figure is Sokar's**: written into `/etc/sokar/tmux.conf`
when the image is built and read explicitly by `task attach`, so no base image or dotfile changes
it underneath the one process that has to state it. The screen says *the last 10000 lines and no
more*. A figure is the honest form of *"what may re-entering claim"* — *as much as we have* leaves
somebody guessing whether the quiet hour is missing or was simply quiet.

## The terminal owns the keyboard, or `Escape` never arrives

The frame holds a focus node for whatever is open, and hands the keyboard to it. That costs
nothing for every other view, because they are read rather than typed into. **A terminal is the
opposite**: with the frame holding the node, `Escape` closed the pane and the far end never saw the
key — which would have made `vim` unusable inside a session, silently.

Found by asking where the key went, in a throwaway test that printed what the far end received,
rather than by assuming it arrived. The session's terminal is now given the frame's own focus node,
and the pane's way out is its header control rather than `Escape`.

## Nothing forks out of Dart

The obvious pty is `forkpty` and then `exec` in the child — and the child returns into the Dart
runtime, in a process whose other threads no longer exist. That is a hang that happens once a week
and never in a test.

`posix_spawn` with `POSIX_SPAWN_SETSID` does the fork and the exec inside libc, where no Dart code
runs, and the child takes the terminal by **opening it as a session leader without `O_NOCTTY`**.
That is what makes `Ctrl-C` reach the far end and lets `SIGWINCH` arrive at all.

Two things that came out of writing it rather than taking a plugin. **libc answers a missing
command itself** — `posix_spawnp` reports the failed exec back to the caller, so *"there is no
`sokar` here"* is a refusal to open rather than a session that appeared for an instant and exited
127; the two read differently and should. And **a blocking `read` needs somewhere to block**:
`dart:io` cannot wrap a descriptor it did not create, so an isolate sits in `read(2)`, posts what
it gets, and reaps the child when it ends.

## Cancelling a broadcast subscription settles a turn late

`await subscription.cancel()` before closing a channel put the close **behind the frame that had
already reported the session gone** — the window said it had left while the far end was still
attached. Caught by a scenario that asked the fake whether it had been closed, not by reading the
code.

The subscription is cancelled without waiting and the channel close is what is awaited. Order the
awaits by what somebody can see, not by the order the fields were declared in.

## The frame branches on the width under the rail

`WindowSize` is read from the `LayoutBuilder` constraints inside the frame, not from the window —
correctly, because the rail is chrome. It means **a 1400-pixel window is not a wide one**: an
extended rail is 256 of them, and 1144 is one class down, where what is open takes the space the
work list had.

A scenario written at 1400 to prove *"the work stays visible beside the session"* proved the
opposite and looked like a bug in the session. Pick the number by what is left after the rail.

## Reasoning attached to one half of an answer says nothing about the other half

QF5 came back as *"a recurring job does not belong to a project, and there will be no scheduler"*,
followed by a paragraph explaining why a schedule is a capability rather than a field. The question
here had been about **storage** — whether a named parameter set could live in `project.yml` — so
the reasoning was read as answering something else, and the question was asked again.

Then it was withdrawn, on the reading that a flat clause with no reason attached is still an
answer. **Both readings were guesses about somebody else's meaning, and the second was wrong**: the
author said the timer was what he refused and that storage alone was not decided. The withdrawal
and the answer crossed in the same minute.

The lesson is not *ask twice* or *never ask twice*. It is that **the only party who can say what an
answer covers is the one who wrote it** — so when a two-part answer is ambiguous, ask once, plainly,
and then wait rather than reasoning about which half the reasoning belonged to.

## A project file describes constraints, not instructions

Why a template is not shared with the project, settled by the operator on 2026-09-08 and worth
holding on to beyond templates.

Everything in `project.yml` is a **bound**: what work here may reach, how far it is trusted, what
image it runs in, how far it may go. A prompt is the other kind of thing entirely — it is what a
model is *told to do*. Put an instruction in a committed file and it **arrives with the
repository**: whoever can commit could put words in front of an agent that somebody else starts,
and nothing in a container fixes that, because an agent acts on what it reads and no boundary makes
a model treat a sentence as data rather than as an order.

A second edge, moot once the answer landed but worth the same shelf: a stored job could have
carried `clearance: off`. Somebody who types a job name does not necessarily read the file, so a
committed line could quietly have turned off the thing that asks.

**Sharing is not this product's problem to solve.** A team that wants the same named jobs keeps
them in a repository of their own — they are text, and teams already share text.

## The word was ours, and it sent the answer somewhere else

The field said *"Keep this as a recurring job"*. It reads as **recurring on its own**, and the
backend answered a question about schedulers that nobody had asked — twice, across three exchanges,
before it was clear the storage half had never been decided.

It now says *"Keep this as a named job"*, and the helper carries the two things somebody would
otherwise assume wrongly: **it stays with you rather than with the project, and nothing starts it
but you.**

When an answer comes back about something adjacent to what was asked, check the wording of the
question before deciding the answer was wrong.

## Removing a project is not deleting it, and the contract says which is which

`DeleteProject` removes **what Sokar built**: the mirror, the image, the build directory, the
registry entry, the recorded upstream distance, and every task with its container, state and logs.
The `project.yml`, the operator's checkout and their real upstream are untouched — and afterwards a
task run in that directory builds all of it again, which is what makes the action safe to offer at
all.

**`keeps` exists because this end said it would have listed `project.yml` among the casualties and
believed it.** So the contract names what survives, and a confirmation can say so without a client
having to know which things are Sokar's. Never work that out here: a client that guessed would
sooner or later name the operator's own file among the losses.

**Two refusals, and they are not the same weight.** A running task is work cut off mid-flight and
the operator still has their repository. An unreviewed push is in the mirror and **nowhere else** —
not in a checkout, not upstream — so forcing past it is the only action in this product that
destroys something no other copy of exists. They get different sentences on screen for that reason.

`force` is a second decision about something the machine declined, never a retry: the button
changes its word to *"Remove it anyway"* rather than staying the same and quietly meaning more.

**It takes the project's name, not its file.** So it is offered for a project whose file nothing
can find any more — which is exactly the one somebody wants to clear away, and the one every other
project action is unavailable for.

## The field name in a message is not the field name on the wire

The Sokar side offered a field and called it `gitIdentity`. On the wire it is **`commitsAs`, of
type `GitIdentity`** — the first is what an agent's own manifest calls it internally. Reading the
name from the message would have compiled, run, found nothing, and drawn a blank field with no
error anywhere.

Checked against the IDL before a line was written, which is the fourth time in one day that
verifying rather than believing changed the result. **A name in prose is a description of a field.
The IDL is the field.**

## The gate is not a wall, and the screen says so

Work can be pushed straight upstream by hand, past the gate entirely. Sokar's guard is a **pre-push
hook, installed per clone, on whichever machine somebody pushes from** — very often not the machine
this interface is talking to, and over a forwarded socket not reachable from here at all. So the
gate view says where that happens rather than offering a control that could only ever protect one
machine.

**It is a loud accident-catcher, not a control**, and the backend is explicit about the four ways
round it: `--no-verify` (which is the point — somebody who means it can still do it), a
`core.hooksPath` pointing elsewhere, a fresh clone, and a client that does not run the git command.
Nothing here may present it as prevention.

## A secret never crosses this socket, and the reason on screen must be the narrow one

Settled for the vault and again for authentication: `Credentials` answers names, kinds and lengths
and never a value, and **no method will ever take one**. Typing a credential happens where the
person already is — they hold an ssh connection to that node, because that is why the socket is
here at all — so the screen shows **the command**, not a disabled field.

**What the rule does not buy, said so nobody puts it on a screen.** It is not transport security:
the socket is forwarded over ssh, so it is the same encrypted connection either way, and anybody
who can forward it can already run commands on that node. What it buys is narrower and worth
more — the plaintext never enters a GUI process (no widget state, no clipboard, no crash dump),
never enters the varlink layer (where JSON reaches logs, traces and echoed errors), and the
invariant stays absolute instead of becoming something every future code path must remember.

**The command is handed over, never composed here.** A credential's key is the provider's name,
falling back to the agent's for older vaults, so a client lining two lists up would report one
missing from exactly the vault that has it. **Third time this shape has appeared** — the
credential rule for starting work, the gate join, and now this. When a client *can* compute an answer from two
lists, that is not evidence it should.

## Verify a forward by connecting through it, never by an exit code

Measured on the Sokar side, and it generalises to everything this interface raises: with something
already bound on the local side of an `ssh -L`, **ssh exits `0`, stays alive, and prints
`bind: Address already in use` on stderr only** — then binds `[::1]` anyway, so the forward is
*half* up. Whether anything works depends on how the client resolves `localhost`.

This end already refuses to believe a path that merely exists — it requires a real
`unixDomainSock`, and clears a stale one first — but the general rule is stronger and is the one to
keep: **a forward is proven by something coming back through it.**

Also measured there, and useful if a second forward is ever needed: `ssh -S <ctl> -O forward -L …`
adds one to a connection already held, and `-O cancel` removes it, both without reconnecting. That
needs a control socket, which the managed tunnel deliberately does without — but re-read, **that decision forbids
sharing the person's own master, not having a private one.**

## A secret may be transferred; it must never be stored

The rule was *"no secret crosses this socket"* for about twenty minutes on 2026-09-08, and then
changed in this interface's favour. **The reasoning that changed it is the part worth keeping**,
because it was nearly inherited as fact.

The argument against transferring was that plaintext should not pass through a GUI. The alternative
it recommended — type it at the machine — puts it through a browser, a clipboard, a terminal
emulator's paste buffer and its **scrollback**, which many terminals write to disk. Measured on the
Sokar side: `vault put` read a typed credential through the *echoing* stream, while the vault
passphrase had always been read without echo. **The advice pointed at the path that wrote the
secret down.**

So `StoreCredential` will exist, and **the obligation moves here, where no daemon can enforce it**:

- never persist what is transferred — not local storage, not a form draft, not a crash report, not
  an undo buffer;
- clear the field after sending;
- never re-display the value. `StoreCredential` answers the key, the kind and the **length**, which
  shows a paste arrived without becoming the place it appears.

`Credentials` stays read-only the other way. **Reading one back and putting one in are different
acts**, and only the second has somebody present who already knows it.

And the strongest point in that exchange was neither side's: **a long-lived key is carried around
whatever route it takes, and the mitigation is a short lifetime.** That is why a phantom token
expires — the route is the smaller problem.

## Ask before building a view for a relation

Key routing asked which keys reach which project, in both directions, editable in place. **The relation
does not exist**: a credential is keyed by the provider's name, falling back to the agent's, and no
project file names a key. Restated correctly it is *"which agents may this project use"* — the
roster, already settled as never.

Nothing was wasted only because it was asked first. A view had been designed for a link that could
not be made or unmade, and it would have looked finished. **Three times now the honest answer to a
requirement has been "that is not a thing this system has"** — the roster, hardware, and this — and
each time the criterion was reworded and the screen made to say why, which is worth as much as a
feature and costs a paragraph.

## When a rule moves, check what was resting on it

*"No secret crosses this socket"* was the second of two reasons why `Unlock` would never exist
here — the first being that a daemon has no terminal to take a passphrase at. The rule was
withdrawn the same day: a credential may be **transferred**, and only keeping it here is forbidden.

**If a value can be sent, a daemon does not need a terminal to take one.** So a screen saying the
store *"can never"* be opened from here was resting on a reason that had moved, and it said so with
more confidence than anything supported. It now says **where** unlocking happens rather than
promising it will never happen anywhere else.

The habit worth keeping is not the correction, it is the sweep: **when an answer changes, look for
what was built on the old one.** Two screens and an index row were, and none of them would have
failed a test — they would simply have been wrong, in the confident register that is hardest to
notice.

## An answer that moves three times is a question that was not ready

The rule on secrets crossing the socket, on 2026-09-08: **refused both halves → refined to
*transfer yes, storage never* → parked.** Each step was reasoned and each reversed something built
on the step before.

What made it survivable here was not being right. It was that **the screens said *where*, never
*never***, so none of them had to change through any of it. The record changed three times; the
product changed once, and in the direction that was true throughout.

**Two of the three original arguments failed under examination** — the *capability boundary* for
the passphrase, because anybody with a shell can already unlock and `--passphrase-command` has
always existed; and the *do not route plaintext through a GUI* argument, because the alternative
routed it through a browser, a clipboard and a terminal's scrollback. That is why the operator now
holds the passphrase and the credential together rather than settling either quickly.

**The habit: when a rule is young, write the screen against what is true rather than against the
rule.** *"This happens at the machine"* survives every version of that rule. *"This can never
happen here"* survived one of them.

## A secret cannot be erased in a managed runtime

From the Sokar side's own design note, and it applies here at least as much: a moving collector
copies objects, and strings are immutable in Dart as in Java. **Any promise that this interface
*wipes* a secret asks for something the language cannot deliver.**

What is achievable is **fewer copies, shorter lifetimes, and never at rest** — and that is what may
be claimed. If a field for a secret is ever built here, it is also worth knowing what the platform
does not give us: on **Linux/X11 there is no screen-capture protection and no secure keyboard
input at all** — any client may read any window and grab the keyboard. Wayland is better and, by
their own note, unmeasured per compositor.

## Two guards for one rule leave both untested

`Node()` says which node a daemon is, so two entries in the machine list can be told to be one
node reached twice — which a client cannot work out, because a hostname has many spellings and a
socket somebody else forwarded looks nothing like a tunnel raised here. The failure it prevents is
not cosmetic: **the same node listed twice delivers every clearance question twice, and answering
one leaves the other on screen until it expires.**

The rule that matters is **an empty id is not an identity** — a daemon older than the method
answers nothing, and two machines both saying nothing are not thereby one.

It was written twice: once where the answer is recorded, once where two are compared. **Both
mutations survived**, because each guard covered for the other. The rule now lives in one place —
the comparison, where it means something — and recording keeps whatever came.

**And the feature scenario could not test it**, because the local machine records its id as the
frame comes up, so a step can only ever clear one of the two. It is held by a unit test that builds
the exact state instead, with the features' own fake rather than a stub written to make one
assertion pass.

## An entry that says more than its name breaks a finder that matched on "contains"

The machine list now appends *"· the same node as X"*. That put another machine's name inside this
machine's line, and the step that switched machines — `find.textContaining(name)`, first match —
started tapping the wrong entry. Nothing failed where the change was; a session two files away ran
the local command instead of the remote one.

**Match a list entry on what it starts with, not on what it contains**, whenever the line carries
more than the thing being matched.

## A rule about future drift needs a fixture from the future

`Health.ready` is the daemon's answer and is never re-derived here — it is the same rule the CLI
exits non-zero on, so the two cannot come to different conclusions about one machine.

**Mutating it to re-derive from the probes changed nothing**, and for a while that looked like a
weak test. It was not: today `ready` is false exactly when something is `MISSING`, so the two
agree by construction and no honest fixture can separate them. A fixture where they disagree would
have described something the daemon cannot produce — the sin already recorded twice here.

**The honest fixture is a daemon newer than this build**: a probe in a state this release has never
heard of, which blocks, with `ready: false`. Re-deriving then says the machine is fine, because
only `MISSING` is known here. That is producible, it is what the compatibility rules promise will
happen, and it kills the mutation.

**When a mutation survives, ask what would have to be true for it to matter** — and then ask
whether that state is reachable. Sometimes the answer is a later release.

## Check that the mutation was applied

A mutation run reported *"all tests passed"* on a replacement that never happened: the anchor
string appeared twice, the script asserted uniqueness, and the failure scrolled past above a green
test run. **A guard reported as unproven deserves one check that the measurement itself ran.**

The Sokar side hit the same shape from the other direction on the same day — mutating a class while
running tests that compiled against an installed jar, so two mutations came back "caught by
nothing" and were caught once it was rebuilt.

## Prepared and up to date are different questions

`Project.prepared` says whether an image exists. It is true the whole time an image is **stale** —
built before the project file changed under it — so work would start in something the file no
longer describes and nothing would have mentioned it. `preparedState` says which of `ABSENT`,
`READY`, `STALE` and `UNKNOWN` it is, and the row marks stale separately from absent.

**`UNKNOWN` is never drawn as stale.** It is an image that does not record what it was built from —
an older Sokar, or a project whose file has moved. Nothing knows either way, and a rebuild that
turns out to have been unnecessary is how somebody learns to ignore the word.

**What counts as a change is deliberately narrow**: the base image and the image snippet, and
nothing else. Egress, limits and the upstream change what a task may *do* rather than what it is
built *from*, and marking after an edit that could not have mattered is the same failure wearing
the other face.

## Where a credential belongs is answered, never worked out

A credential's key is usually the provider's own name — but a vault written before credentials were
keyed by provider answers under the **agent's** name, and that key stays in use so upgrading does
not stop anybody authenticating. **A client intersecting "providers" with "stored names" reports a
credential missing from precisely the vault that has one**, because the fallback key is invisible
from outside.

So `credentialName` is read and `storeCommand` is rendered verbatim. **Fourth time this shape has
come up** — the credential rule, the gate join, key routing, and now this. The pattern is
always the same: a client *can* compute an answer from two lists, and that is not evidence it
should.

One detail the command carries that nothing here would have known: a subscription token rather than
an API key needs `--type oauth`, because they go in different headers, and sending one as the other
fails as an authentication error that looks exactly like a wrong key.

## Importing moves no secret, and that is why it is offered

`ImportCredential` names an agent; the daemon reads that agent's own config file **on its own
disk**. Nothing crosses the socket but a name, so it is unaffected by whatever is decided about
typing a secret here.

Three of its outcomes are not failures and must not read as one:

- **`NOTHING_TO_IMPORT` is ordinary** — the agent is installed and nobody has logged in with it on
  that machine yet. The sentence names logging in there as the next step.
- **`VAULT_LOCKED` is not a missing credential.** It is *"we cannot tell you until it is opened at
  the machine"*.
- **`length` and never the value**, which is how somebody sees it worked without the confirmation
  becoming the place the secret appears.

**Omitting the agent means "the only one installed"; an empty string matches nothing.** Two
different things, kept apart on both sides.

## Three rebuild depths, and the middle one is a mechanism

The image layers are base → OS packages → agent layers → project snippet, so invalidating from the
agent's layers genuinely keeps the packages. **But there is no podman flag for "rebuild from layer
N"**: the middle depth works by changing a build argument placed where the agent's layers begin,
which invalidates the cache from that line down. Real, and not free.

That is why it was worth asking before drawing three buttons. **A screen offering three depths
where only two were real would have been a lie about cost**, and a rebuild that costs ten times
what the screen implied is what teaches people not to press it.

`CACHED` is not *"skip the build"*: the build runs and the cache decides line by line, which is
what every task start already does. **The cost belongs on the choice**, not in a warning
afterwards — somebody deciding to rebuild is deciding what it will cost them.

## An apostrophe in a command label breaks the generated test

`bdd_widget_test` writes the step's argument into a single-quoted Dart string, so a label like
*"Build this project's environment"* produces an unterminated literal and the whole build fails
with no output. The command was renamed rather than escaped: a label is read by people, and a
backslash in one is a fix in the wrong place.

## A blank that looks like an answer is worse than no feature

Instructions were withdrawn entirely rather than reworded into something smaller. Standing
instructions live in the repository, checked in or not, and **Sokar does not know what they are
called** — `CLAUDE.md`, `AGENTS.md`, whatever an agent invents next year — nor how a given agent
combines several of them, because that is the agent's rule.

The backend was one step from building a *known set* of filenames, read out of the mirror and
recorded at task start, and said so rather than shipping it. **For a feature whose only job is to
show what an agent was told, a filename that goes out of date produces a confident "no
instructions" for a task that had them.** The screen would have looked finished and been wrong in
the direction nobody checks.

So the work's detail says where they are and that nothing here has a view of them — in the place
somebody would ask.

## Four criteria in this set described relations that do not exist

The agent roster, hardware access, key routing, and per-project authentication. **Every time the
honest answer was "that is not a thing this system has"**, and every time asking first cost a
paragraph and saved a screen that would have looked finished.

The tell is the same each time: a criterion joins two things the contract never joins. A project
and a list of agents; a project and a device; a project and a key; a project and a credential.
**When a requirement asks for a relation, ask whether the relation exists before designing the view
that edits it.**

## `mode: AGENT` now means an agent was really there

`--attach agent` with no agent installed used to attach a plain shell and record `AGENT` anyway, so
a task could say `AGENT` while nothing agent-shaped ever ran in it — and `CanStart` answered
`NO_AGENT` for the same machine, so the check and the launch disagreed. It refuses now, before the
workspace, the image and the container.

Nothing here changed, but what the field *means* did: `AGENT` is now evidence rather than a
recorded intention. **`SHELL` still needs no agent** — working inside the container by hand is
exactly what it is for, which is why a session is offered for it.

## Three different things get called "login"

Only one of them is a flow, and it is not this interface's:

- **Getting the credential** — the agent's own login on the node, once, outside any container. It
  opens a browser and produces a long-lived token.
- **A task authenticating** — not a login at all. The agent holds a phantom token and the broker
  swaps the real credential in on the way out.
- **Logging in inside a container** — blocked and pointless: the ruleset denies the provider's own
  host, and the value would land somewhere that is removed.

So `Login` is held open as *later, nice to have* rather than built. **Somebody at this interface
already holds a terminal on that machine** — the socket only reaches here because it is forwarded
over ssh — so it would save typing one command in a window that is already open.

And it is not free: nothing tells Sokar how to log a given agent in, so it means a new field in the
agent manifest landing in every agent repository, after which Sokar owns a flow it cannot test for
agents it does not ship. **That is the instructions problem again** — per-agent knowledge held
centrally goes stale silently, and being wrong produces a confident failure rather than an obvious
one.

What the screen owes instead is what differs between the ways in — a key and a subscription token
are stored differently, which is why the command carries `--type` — and that getting either is the
agent's own login. **If somebody is observed getting stuck at exactly that question**, the smallest
fix is two strings an agent *declares* and Sokar only *displays*: a login command and a
documentation link. On evidence, not on anticipation.

## The checking is what makes creating a project not a form

Whether a name survives becoming an image tag and an nftables set name, whether an egress set
exists on that machine, whether a class is spelled right — **none of it can be judged here**. An
answer accepted in a dialog and refused at the first task start is refused far from where it was
given.

So every change asks the machine with `dryRun`, which writes nothing, and what comes back is the
file as it would be written plus what is wrong with the answers. **Not on every keystroke**: a
project name typed a letter at a time would ask the machine eleven times to be told the same thing.

Two distinctions the contract makes and the screen has to keep:

- **A problem that blocks and one that does not.** A base image that is not on the machine yet will
  simply be pulled; refusing there would turn a note into a wall.
- **`ALREADY_EXISTS` is a refusal and never an overwrite.** The file may be somebody's whole
  configuration, and this is the one operation that would replace it with nothing to restore from.

And the rendered file is **filled even on a refusal**, because seeing what was rejected is most of
understanding why.

## A `\$` in a generated fixture is a literal, not an interpolation

The fake's rendered project file was written through a script and came out as `"$name"` on screen —
a Dart escape, not a value. The scenario failed on the one assertion that read the rendered
content, which is exactly the assertion that was worth having.

**A fixture built by a script is code somebody wrote twice**: once in the script's quoting and once
in Dart's. Read it back before believing it.

## A record is not the bundle

`Backups` reads a record written when each backup was taken, because `gate backup` writes a bundle
wherever an operator names it and forgets it. **The missing part was never a listing — it was a
question with no data behind it.**

That bounds what the screen may promise: **a bundle written by hand, or before the record existed,
is invisible and always will be**, so an empty list says *nothing recorded* and never *nothing
exists*.

And the two halves are kept apart because they can disagree: **when it was taken and how much it
held are what was true then; whether the file is there and how big it is are read from disk now.**
A bundle somebody moved is shown as **missing rather than dropped** — dropping it would say the
backup was never taken, which is a different and worse statement than *it was taken and you moved
it*.

Deleting takes the **path, not an index**: a list that shifted between somebody reading it and
acting on it would delete a different backup than the one they chose. And a record cleared for a
bundle already gone is a **tidy-up, not a loss**, said differently — telling somebody they
destroyed something they did not is its own kind of wrong.

## Taking a name back stops new connections, not running ones

`NarrowTask` is not the mirror image of widening, and the screen has to say the difference. The
name stops resolving and its recorded addresses come out of the firewall — but **the ruleset
accepts established traffic without consulting the set again, so a transfer in flight runs to its
end.**

Never draw it as *"the host is now unreachable"*: it is not, yet, and somebody relying on that
sentence is relying on it at exactly the wrong moment. **Stopping a transfer is what stopping the
task does**, and that is the honest next step to offer.

Two more the contract states and the screen keeps:

- **Zero addresses with a name taken back is a real state.** The name was granted and the
  container never reached it, so nothing was in the set. Drawing it as a fault sends somebody
  looking for one.
- **The addresses removed are the ones recorded when the grant was applied**, never a fresh
  resolve. A CDN answers the daemon and the container differently, and the ones that differ are
  exactly the ones that would be left open.

## `AGENT` and `SHELL` are the same task

This end refused to open a session for an `AGENT` task until 2026-09-08, on the strength of *"the
agent is the main process, so there is no session to attach to"*. **That was wrong.** Same
container, same egress, same gate, same credential — `--attach agent` only runs the agent's binary
first and drops into the shell when it exits, and attaching starts its own `tmux` by `podman exec`,
which does not care what the main process is.

So the refusal took the action away from the commonest kind of task there is, **with a reason that
was not true**. Corrected when the Sokar side said so.

The lesson is not about modes. **A refusal repeated confidently is the hardest kind to notice**:
nothing failed, nothing was reported, and the sentence explaining it read like knowledge. When a
rule takes an action away, the question to keep asking is *what would have to be true for this to
be wrong* — and here it was one sentence from somebody who knew.

## Turning enforcement off opens nothing

`SetClearance` changes **whether a blocked connection produces a question**, not what a container
can reach: the ruleset is loaded throughout. And it undoes nothing — a connection already refused
stays refused, because the packet was dropped and nothing retries it, and anything waved through
while nothing was asking stays through.

It is deliberately **not** widening with a special value. Those grant and withdraw names, and that
the firewall stays loaded is what they mean; folding *"stop asking about anything"* into them would
make one method mean two unrelated things, **and the quiet one would be the dangerous one**.

`UNCHANGED` is not a failure: it was already in that mode and nothing was restarted, which deserves
a different sentence from a change that happened.

## A refresh announces itself, so say the result after it

Changing enforcement said what it did and then refreshed the list — and the refresh's own
*"Refreshed: 4 tasks"* landed where the answer to what somebody just did should have been. Caught
by a scenario reading the status line, not by looking.

**Order the two by what somebody needs to see last.** Anything that announces itself belongs before
the sentence about the thing they actually asked for.

## A triggered fetch is its own call, never a flag on a listing

`SyncUpstream` exists rather than a `refresh` parameter on `Projects`, for a reason the Sokar side
enforces with an architecture rule: **a listing that reached the network would make the queue cost
what a listing must not** — occasionally thirty seconds, for reasons nothing on screen explains.

It goes through the same measurement the daemon's timer uses and writes the same record, so a
triggered fetch and a timed one cannot disagree, and `Projects` shows whichever ran last without
being told.

**`behind` still means nothing unless it was measured**, in the answer as in the listing. Zero is
what a project that is up to date reports *and* what one nothing could be measured about reports,
so the sentence names which — no upstream, offline, never checked — rather than saying *up to
date* to both.

## Restoring destroys the only copy there has ever been

`RestoreBackup` refuses with `HOLDS_WORK` and names the refs, the same shape `Stop` and
`DeleteProject` already use — a third use rather than a fourth invention.

`gate restore` already refused to write over a mirror, which was right and said nothing useful.
**What was missing was naming the cost**: unreviewed pushes exist only in the mirror — not on the
upstream, not in a workspace, not in the bundle.

And `force` **reports what it destroyed afterwards**, not only before. Somebody who forced past a
refusal needs that in the record, not only in the warning they clicked past.

**Restoring from a bundle that is not there is not offered.** The record is listed, because the
backup was taken — but there is nothing to restore *from*, and offering it would say the record is
the thing when it is not.

## Name or file: four methods say only `project: string`

`Prepare` documents *"absolute path of the project file"* and `DeleteProject` documents *"project
name"*. **`Backups`, `DeleteBackup`, `RestoreBackup` and `SyncUpstream` document neither** — and
they take the **name**, which was established by reading `BackupRecords` (one record file per
project name) and `UpstreamSync.sync` rather than by guessing.

**Getting it wrong here fails in the worst possible shape**: passing a path answers an **empty
list**, which this screen deliberately renders as *"nothing is recorded for this project"*. A wrong
argument would arrive as a legitimate answer, on the one screen built to insist that absence means
absence of a record and not absence of a backup.

Every project-scoped call in this interface therefore names which it passes at the call site, and
the mock keys its records by name for the same reason — a fake that accepted either would hide it.

## What a task holds: three answers, and a fourth that is not one of them

`WorkHeld` is asked for **one task when somebody opens it**, never while drawing a list — it runs
git inside the container, so on a list this interface redraws it would be a call per row. That is
the cost `since` and `behindMeasured` both exist to avoid, and it is why this is a method rather
than a field on `Task`.

The three the screen must keep apart:

- **Holds nothing** — `readable: true` with two zeros.
- **Holds this much** — the counts, worded here rather than received as a sentence.
- **Nobody could look** — `readable: false`: killed, rebooted, or stopped by a Sokar that left no
  note. **Absence rendering as nothing-to-worry-about is what `readable` exists to prevent**, and
  it is the third field to carry that flag after `Credentials` and `Providers`.

And the fourth, which is not an answer at all: **a name that is no task raises `NoSuchTask`.** A
client's wrong argument must not arrive as a legitimate reading — the shape that cost an afternoon
on `Backups`, where a path answered an empty list on the one screen built to insist that empty means
*no record*.

**`asOf` separates *holds* from *held*** without correlating against `Task.state`, which would be
two answers a client has to keep agreeing about. Absent means current; present means the workspace
is inside a container that is down and the only source is what the stop wrote.

## Counts, not a phrase — the rule that decides which

The Sokar side first offered a rendered sentence and then withdrew it themselves: a phrase is
English, a fixed plural rule and a layout that has to accept it whole, and a number never received
cannot be badged or sorted.

The rule that decides, in both directions:

- **Render verbatim what only they can compose** — `storeCommand`, whose key comes from a fallback
  invisible from outside; a probe's next action; a refusal's own words.
- **Take the parts of what they would only be wording for you** — counts, states, instants.

The test is not who is more convenient. It is **whether the sentence contains knowledge this end
does not have.**

## A name is data, never a category — not every log is called `.log`

`Logs` answers file names, and **nothing at this end may narrow that answer by what a file is
called.** The daemon shipped a suffix rule of its own for a day, and it hid `events.jsonl`: what
the firewall blocked, which is the file to read when a task starts and then does nothing. The same
rule written here would hide the same file, and no test of the daemon would ever see it.

That is why the mock serves four logs and two of them are not `.log` — one of them zero bytes, so
a rule that hides empty files fails too. A fixture that only ever holds the shape the code already
handles is the shape Sokar's own bug had: a parser and its test agreeing with each other and with
nothing else.

The scenario is the guard, and it is worth the mutation every time: put `.endsWith('.log')` into
the picker and **the file a stuck task needs disappears from the list while every other log test
still passes.**

### And what a name cannot say, the daemon says — never a table here

`Log.what` is one line about what a file holds, absent where the name speaks for itself. It was
tempting to keep that table at this end, since there were only two names to describe. Two reasons
not to, and they are the reasons it belongs at the other end:

- **A table here drifts silently.** They add a file; the list grows; the new one has no sentence
  and looks exactly like the ordinary case.
- **A table here becomes a second source for one sentence.** When the field arrives, the two
  disagree and both look authoritative.

`_optional` exists for it and is not `_string`: **absent, empty and whitespace all read as
nothing**, because a blank line under a name says *this file has a description and it failed*
rather than *nobody gave one*. Mutate it to `_string` and four tests go red, one of them the
scenario that a bare name is described by nothing at all.

## What the build reports

`tool/test_report.dart` parses `flutter test --machine` once and writes four things: the HTML page,
JUnit XML, a table on `$GITHUB_STEP_SUMMARY`, and an `::error` per failing scenario on its line in
its `.feature` file. One parse, because a build that reports twice reports differently.

- **The machine JSON, not the JUnit XML.** It is the source the XML is made from, and it carries
  the failure text and timings the XML flattens away.
- **`classname` is what the feature tests**, and the row shows the last two path segments. The
  requirement ids are gone: a finished requirement's file is deleted, so a row headed by an
  id named a document nobody could open. `test/features_named_test.dart` fails on any id left
  in `lib`, `test` or `tool`; `test/docs_test.dart` fails on one in the docs, and on a dead link.
- **The table is Sokar's, column for column**, so two reports of the same kind of run read alike.
  Failure detail is in the annotation only — a summary that grows a stack trace stops being
  scannable at the first red build.
- **`--machine` reports `time` as milliseconds since the run began**, on `testStart` and
  `testDone` alike. Read as a duration it makes each row the age of the run at that point; the
  column summed to four times the wall clock before anybody looked.
- **No action and no `permissions:` block.** The summary is a file the runner hands you and the
  annotations are stdout. A check run would want `checks: write`, which is a decision about a
  repository rather than a detail of a report.
- **`GITHUB_ACTIONS` and `GITHUB_STEP_SUMMARY` are separate switches**, so both surfaces can be
  driven from a terminal without pushing.

Two things only a deliberate failure showed, and both were invisible while everything was green:

- **A widget test's `error` event says only *"Test failed. See exception logs above."*** The
  expectation, the actual and the author's `reason` are in a `print` event. The HTML report had
  been built on `error` alone since it was written, so every failure in it was that one sentence.
- **A workflow command is one line.** An unescaped newline ends it and prints the rest as ordinary
  output. Removing the `%0A` escape takes exactly one test red.

Sokar's rule, which found both: **make a scenario fail on purpose and read what comes out.** The
happy path proves nothing about a failure report.

And a third, from their side: **a reporter that writes nothing when it has nothing to report cannot
be told apart from one that never ran.** Their acceptance suite proved nothing for several merges
because a CI line named an aggregator, so the step passed in seconds and the absence of results read
as a build with no test step. An empty run here writes *"No tests ran"* on the summary page and
exits non-zero — the page makes the state visible, the exit code makes it unmergeable.

## The window opens on what needs a person

`Attention` reads every machine's existing `FleetModel` and `Clearance`; it opens no stream of its
own, so it cannot disagree with the Blocked section. Before it, the Blocked section and its badge
showed the current machine only, and another machine's question reached nobody but a notification.

- **The keyboard has to land where the window opens.** Starting on the new view with focus still
  aimed at the projects pane left every shortcut dead until something was clicked. A scenario now
  opens the command finder straight after launch.
- **Work is a precondition, and the scenarios say so.** Every Background has *"And I go to the
  work"*, and so does every scenario after a restart, which lands on this view again.
- **A deadline is time left, and absent is not empty.** No `deadline` is a daemon older than the
  field (*"does not say when"*); `""` is a question that never runs out. The tile ticks while one is
  on screen: a countdown that does not move overstates the time left.

## Integration tests against a real machine

`tool/e2e.sh` runs the features in `integration_test/` against the machine named by
`SOKAR_E2E_HOST`, `SOKAR_E2E_REMOTE_SOCKET` and `SOKAR_E2E_KEY`. The app gets its own config and
runtime directory and ssh a private agent, so a running interface and the person's ssh setup are
left alone.

- **Headless only, under xvfb.** A test window on somebody's desktop takes their keyboard.
- **Composed once per process.** The framework clears the widget tree between scenarios, so each
  shows `sokar()` again; composing twice would find its own instance lock and exit.
- **The remote socket is asked of the machine, never guessed.** The uid differs between machines,
  and a guessed path looks like a machine that never answers.
- **Its first find was real:** a forward whose far end has no socket resets the connection, and
  the failed write escaped unhandled because nothing waited on the socket's `done`.
- **A test ending is not a window closing.** Nothing drops the forwards the app raised, and
  eleven runs left eleven ssh sessions open to the VM. `tool/e2e.sh` now kills every forward
  raised under its own directory when it exits.
- **Maven rents the machine.** `./mvnw verify -Pe2e,hetzner` leases one with Sokar's
  `sokar-machines` in `pre-integration-test`, and `tool/e2e.sh` reads `build/leased.properties`.
  The run never fails its own phase: it leaves its status in `build/e2e.status` and `verify` fails
  from it, so the sweep in `post-integration-test` runs on a red test too. Maven would otherwise
  stop at the failing phase and leave the server billing.
- **The key is material in CI, a file for a person.** CI sets `HETZNER_SSH` and passes no
  `--key`; the secret is never written to disk, and `tool/e2e.sh` pipes it into its agent. A
  person sets `HETZNER_KEY` to the file. `HETZNER_API` is the token in both.
- **The snapshot repository is in `settings.xml`**, not in the pom, and every CI call passes
  `-s settings.xml`, as the agent repositories do.
