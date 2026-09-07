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
- **Unknown values must not be fatal.** Ignore reply fields you do not recognise and render an
  unrecognised enum value rather than throwing on it. Adding an enum value is explicitly *not* a
  breaking change, and `Outcome` will gain entries. **A generated Dart enum with no fallback case
  is how this rule gets broken** — it will look correct until a routine backend release.

The build version from `GetInfo` is for display and bug reports. Never gate a feature on it.

## Code

- **Dart 3.13, Flutter 3.47 stable.** Pinned in `pubspec.yaml`.
- **Comments say why, not what.** The useful ones name a constraint, a measurement, or a bug
  that already happened. An inline comment is **one line** — not one sentence over three. The
  reasoning that does not fit is a finding, and findings go in this file where they can be found
  without reading the code.
- **British-leaning spelling** in prose and comments: behaviour, recognise, serialise.
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
- **Test observable behaviour**, not internals — what is on screen, what went down the socket.
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

**Projects are derived from `Task.project`, not asked for.** There is no method that lists
projects, so a project that has never run anything is invisible in the opening view. That is
[F02](requirements/F02-Project-Overview.md), it is a real gap, and the empty state says so rather
than implying the machine is bare.

Two interface traps already met:

- **An `InkWell` with both `onTap` and `onDoubleTap` holds every single tap back** until the
  double-tap timeout passes. Rows select on a single tap and open with Return or a named
  affordance; do not put double-tap on a row to open something.
- **A widget built eagerly outside the branch that shows it still runs its null checks.** A
  detail pane built before the `if` that needs it crashed the whole frame with nothing selected.

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
cannot be made to produce on demand: `MethodNotFound` for the degradation rule, an unrecognised
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
  asynchronous error fails whatever test happens to be running. Cancelling a stream is an ordinary
  act, so the mock absorbs it.
- **One CI job runs against a real daemon** and compares the mock's surface against
  `GetInterfaceDescription`. The mock proves the client handles what it is sent; that job proves
  the contract is what we think it is. **A drifted mock is worse than no mock.**
- Unix socket paths are limited to about 108 bytes on Linux, and test temp directories reach it.

## Analysing and formatting

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
  expensive facts and the traps — moves into this file. The set is what is left to do, not a
  history of what was done; the history is in git.
- A file ending in **To be checked** has something unresolved that could change what it
  promises, and its index row is marked as an open question.

## Commits

One brief line. The reasoning behind a change is a finding, and a finding goes in this file
where it can be found later without `git log`.
