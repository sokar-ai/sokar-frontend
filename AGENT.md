# Working on the Sokar frontend

The interface people use to work with a [Sokar](https://github.com/fuinorg/sokar) backend, in
Flutter. This file is the working knowledge: the rules, the traps, and the things that were
measured rather than assumed. What must be *true for a person using it* is in
[requirements](requirements/README.md); what it is *made of* is in
[design](requirements/design.md).

## Start here

The frame and the client exist; the rest of the product does not. In order:

1. **[Backend API](doc/Backend-API.md)** — how to talk to the daemon, and the compatibility
   rules. Do not write a call before reading it.
2. **[What the contract does not yet cover](doc/Contract-Gaps.md)** — roughly half the
   requirements have no backend method behind them. Which half is not obvious. Read it before
   picking a requirement, not after designing a screen for one.
3. **[Design](requirements/design.md)** — what this is made of and why: Flutter, testing, the
   mock, packaging.
4. **[Requirements](requirements/README.md)** — the work, ordered, with a **Backend** column
   saying what is reachable today.

Green means `dart analyze` at "No issues found!", `flutter test` passing, and
`flutter build linux --release` producing a bundle — measured 2026-09-07 at 13 s and 23 MB.

[F01](requirements/F01-Application-Shell.md) is built: `lib/src/app/` is the state the frame is
drawn from, `lib/src/ui/` the frame itself. To open it against no daemon at all:

```
dart tool/mock_daemon.dart          # prints the socket, and a situation to choose
SOKAR_SOCKET=<that socket> flutter run -d linux
```

`SOKAR_SOCKET` is the only way to point the interface anywhere but the local daemon today.
[F20](requirements/F20-Access-From-Elsewhere.md) replaces it with something a person can choose;
until then it is what the mock and a forwarded socket both use.

## The one architectural rule

**Everything goes through the varlink contract. Nothing shells out to `sokar`.**

**And a method existing is not the requirement being covered.** Four requirements sat in the
*ready* column of [Contract-Gaps](doc/Contract-Gaps.md) because the obvious method existed;
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
a machine nobody is connected to is one whose blocked work expires unseen. Which machine an action
lands on is a separate question, answered by the switcher **pinned above the rail** and never by
which host happens to be reachable. It is pinned rather than scrollable on purpose: a host that is
a collapsible ancestor in a tree scrolls out of view, leaving a row that does not say which
machine it is on, and that is how somebody stops a task on the wrong one.

A host is a name and a socket path, and raising the forward is somebody else's job —
[F27](requirements/F27-Managed-Tunnels.md) is the interface doing it, and it must never become the
only way in. Running `ssh` would not breach the no-shelling-out rule, which is about never
re-implementing the *domain* through the CLI; `ssh` is transport.

**Three surfaces, one list of actions.** The rail says *where you are* (sections), the menu bar
says *what you can do*, the command finder is *how you find one fast*. All three read
`commands.dart`, so an action added once turns up in all of them and a shortcut cannot come to
mean something other than the entry naming it. None of the three is redundant: they answer
different questions.

**A pointer must be sufficient, not merely optional.** F01 says "every action is reachable from
the keyboard alone; a pointer is optional everywhere, never required" — and the first build of the
shell inverted it. Appearance, reconnect and quit were reachable *only* through the finder, so the
pointer was the impossible half. The menu bar is the fix, and the scenario *every action is
reachable with a pointer alone* is the guard that should have caught it.

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
arriving late does not mean having missed the output. That is the whole class: F13 is the
machinery, and F03, F06 and F08 are the things that will use it.

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

**The egress editor, when F05 and F17 are built** — `Egress` and `SetEgress` landed 2026-09-07 and
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

**A clearance decision is remembered per address, not per name, and survives a resume.** One fixed
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
Renaming work and recreating it from scratch are both F09 criteria with nothing behind them. An
action that simply is not there reads as one nobody thought of; one that says *"the backend has no
method for renaming work"* reads as what it is. `workCommands` builds the row's own menu and the
menu bar's entries from one list, so neither can offer what the other forgot.

**`Projects` lists every project, not only the busy ones**, and gives both `tasks` and `running`
rather than leaving one to be inferred. A project with nothing running is the ordinary case —
between tasks, or after one was stopped and can still be resumed, which keeps its workspace. A
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
  for them. `Scope.run` does not survive a `Resume`: a resumed container rebuilds its ruleset and
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
  cannot assemble the answer from parts it has, and F08's sixth criterion waits for a method that
  answers the whole question.

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

- **F08**, because `Start` exists and starting is one call. The call had no parameter for two
  thirds of what the requirement asked for.
- **F24**, because `Agents` exists and answers a list. Two of its four criteria — the pinned build
  and its digest, and which copy of a shadowed name is in use — have no field behind them.

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

**Templates follow the person, not the project.** F25 asks for them shared with the project, and
nothing in the contract writes to a project file except `SetEgress`, so they live in this
interface's settings. That is a shortfall recorded in the requirement, not a design.

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

