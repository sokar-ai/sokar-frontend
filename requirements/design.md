# Design

How this interface is built. The requirements say what must be true for a person using it; this
says what it is made of. One section per decision, each with the reason it was taken — a decision
without one gets re-argued every time somebody new reads it.

## Flutter

- **Language:** Dart 3.13, Flutter 3.47 stable. Pinned in `pubspec.yaml` once the app exists;
  until then these are what the decisions below were taken against.
- **UI:** Flutter, one codebase for desktop and tablet. **Linux desktop is the only target that
  works today** — the backend is a unix socket, so a client has to be able to open one, and a
  phone cannot without a tunnel it has no way to raise. Phone is not designed out; it is simply
  not reachable until [F20](F20-Access-From-Elsewhere.md) says how a device without a shell gets
  a socket. Do not build layouts that assume it will never arrive.
- **Contract:** the Sokar backend and its API contract — the varlink interface
  `org.fuin.sokar.Tasks1`, over one unix socket. **No REST, no HTTP, no shared code with the
  backend at all**: the only thing crossing the boundary is the IDL, which the daemon serves
  from itself. See [Backend API](../doc/Backend-API.md) before writing a call.
- **Client:** hand-written, in one package, against the contract. There is no varlink code
  generator for Dart and the protocol is small enough — a socket, JSON objects, a NUL between
  them — that generating it would be more machinery than it saves. Whether that stays true once
  every method has a typed request and reply is the open question below.
- **Auth:** **none, and that is the design.** The socket is owner-only, so the filesystem decides
  who may connect and there is nothing to log in to. A remote backend is an SSH forward, so its
  authentication is SSH's. If a design here starts needing a token, a session or a login screen,
  something has gone wrong upstream of it — say so rather than building one.
- **Build:** `flutter build` and nothing else. This repository is not in the backend's Maven
  reactor and must never need it: the point of the split is that the interface builds, tests and
  releases on its own, on a machine with no JDK on it.
- **Test:** `flutter test` per package. **`dart analyze` must stay at "No issues found!"** — and
  it is `dart analyze`, not `flutter analyze`: the latter has been seen to rewrite
  `analysis_options.yaml` with an exclude block nobody wrote, which silences findings instead of
  fixing them.

## Testing

Tests are written as Gherkin `.feature` files and run as ordinary Flutter widget tests, via
**[`bdd_widget_test`](https://pub.dev/packages/bdd_widget_test)**, which generates the tests from
the features.

- **Why that one, measured rather than assumed.** It is the only live option in this space:
  `sdk: ^3.7.0`, 63k downloads, 181 likes — against `flutter_gherkin` (declares `sdk: <3.0.0`,
  changelog ends May 2021, pins `gherkin ^2.0.2` while that is at 3.1.0, drags in the legacy
  `flutter_driver` stack), the `gherkin` package itself (`sdk: <3.0.0`, changelog ends July
  2022), and `bdd_flutter` (41 downloads).
- **It generates real tests, which is the whole point.** A feature becomes a `group` and each
  scenario a `testWidgets`. Every other Gherkin option for Dart is a *parallel runner* with its
  own reporters — `flutter_gherkin` contains no `testWidgets` and no `group` anywhere — so its
  scenarios never become `package:test` events, never reach JUnit XML, and never appear
  individually on a build server. That single fact decided this.
- **Results on the build server:** `flutter test --machine | tojunit`, from `junitreport`
  (228k downloads). Verified end to end — a two-scenario feature produced:

  ```xml
  <testcase name="F09 Task Control a task holding unpushed work is refused" .../>
  <testcase name="F09 Task Control a task with nothing held is stopped" .../>
  ```

  Because the feature name carries the requirement id, **the CI test report is a requirements
  traceability matrix** — per-requirement pass and fail, with no extra tooling.
- **The requirement id goes in the `Feature` line, never in a scenario name.** Reworded criteria
  then do not churn ids, and a requirement's scenarios stay collected under one heading.
- **Steps are shared by name.** `Given the app is running` resolves to
  `test/step/the_app_is_running.dart` across every feature that uses it, and the generator
  scaffolds the file the first time. So step wording *is* the API: phrase a step the way you
  want to reuse it, and vary the data rather than the sentence.
- **Binding is checked, not maintained.** A test asserts every requirement file has at least one
  feature naming it, and that no feature names one that no longer exists. Bind at requirement
  level, never at bullet level — acceptance bullets get reworded constantly. A table nobody
  checks is a table that lies; the same trick keeps the backend's IDL honest.

Traceability is not completeness: a requirement with one shallow scenario shows as green as one
with twelve. Only reading the scenarios fixes that, and no framework changes it.

### To be checked

- ~~Whether generated `*_test.dart` files are committed.~~ **Decided: committed**, with CI
  proving they are current by running `build_runner` and failing on a diff. Ignoring them was the
  first instinct — one source of truth, as with the IDL — but it has a failure mode the IDL does
  not: a CI job that forgot to run `build_runner` would find no tests and report green. A
  committed file plus a diff check catches drift *and* cannot silently vanish.

### How it is laid out, as measured

- **`test/features/*.feature`**, with step definitions in **`test/features/step/`** — beside the
  feature, not in `test/step/`. The generator scaffolds a stub there the first time it meets a
  step, referencing `MyApp`; replace it. A stub left unreplaced fails to compile, which is the
  right way round.
- **Generated tests land beside their feature** as `<name>_test.dart`.
- `dart run build_runner build` after adding or editing a feature. Its
  `--delete-conflicting-outputs` flag has been removed and is silently ignored.
- `avoid_print` is disabled per-file in `tool/contract.dart`: it is a command-line tool and
  printing is its output. That is the only lint exception, and it is stated in the file.

## The mock backend

A mock daemon — a small Dart program binding a real unix socket and speaking real varlink. The
app's own client runs against it unchanged, because the socket path is the only thing that
differs. That is the same property that makes a remote backend work, so the mock costs nothing
extra to reach.

**It is permanent, not scaffolding until the backend is ready.** It produces states a real
daemon cannot be made to produce on demand, and those are the hard requirements:

- `MethodNotFound`, to prove per-feature degradation against an older backend. A real daemon
  always has all its methods, so this rule is otherwise unenforceable.
- An unrecognized `Outcome` value, to prove the tolerance rule. A real daemon only ever sends
  values it knows — and a generated Dart enum with no fallback case is exactly how this breaks.
- `GetInfo` advertising `Tasks2`, to prove the client picks the highest name it understands.
- A stream cut mid-flight, for the requirement that tunnel loss reads as disconnection and never
  as an empty fleet.
- `HOLDS_WORK` on demand, without contriving a task that genuinely holds unpushed commits.
- A four-minute image build, and a clearance prompt with a live deadline.

It also means the test suite needs no podman, no containers and no Linux host with a runtime —
so it runs on any hosted runner.

- **Scenarios are named for the situation, not the requirement** — `task-holds-unpushed-work`,
  not `f09-case-2`. A finished requirement is deleted; the situation and the test guarding it
  outlive it.
- **Events are driven by the test, never by wall clock.** Otherwise stream tests are flaky, and
  flaky tests get deleted.
- **Drift is caught by one CI job with a real daemon**: install the `sokar` package, start
  `sokard`, compare the mock's method and field set against `GetInterfaceDescription`. The mock
  proves the client handles what it is sent; that job proves the contract is what we think it is.
  Neither substitutes for the other, and a drifted mock is worse than no mock.
- **Watch the socket path length.** Unix paths are limited to about 108 bytes on Linux and
  temporary directories in test harnesses get long enough to hit it.

## Packaging

Delivered as a `.deb` and an `.rpm`, from the same repository as the `sokar` package —
[F26](F26-Linux-Packaging.md) is the requirement; this is what it is made of.

- **Output:** `flutter build linux --release` produces a bundle directory — the binary,
  `lib/libapp.so`, `lib/libflutter_linux_gtk.so`, `data/`. Measured at 22 MB and 11 s. The
  package installs that directory, a launcher on the path, a `.desktop` entry and an icon.
- **Dependencies:** derived, never listed. The shipped `.so` resolves the system GTK3 stack, and
  `dpkg-shlibdeps` and rpm's ELF scanner both work that out themselves. A hand-written list is a
  list that goes stale between Flutter releases.
- **Tool:** [nfpm](https://nfpm.goreleaser.com/) — one static binary, one YAML, both formats.
  **Not `rpm-maven-plugin` and jdeb**, which is what the backend uses: adopting them would put a
  JDK back into a build that deliberately has none, and would need `rpmbuild` on a Debian
  runner. What must match the rest of Sokar is the package a person installs, not the tool that
  wrote it.
- **Relationship to the backend:** `Recommends: sokar`, not `Depends:`. An interface talking to
  a remote daemon over SSH is useful with no local backend, and a hard dependency would be wrong
  for that.
- **Where it is published:** into the same Artifactory repository as `sokar` and the agent
  packages. A dependency between packages does not resolve when they are split across configured
  sources — this is recorded in the backend's `AGENT.md` and applies here unchanged.
- **Build machine:** Ubuntu, never Fedora, because the bundle links glibc dynamically — the
  backend's own rule. Flutter adds one the CLI never had: the bundle links the GTK3 stack too,
  so the build machine's GTK is the oldest GTK the package can run against. Build on the oldest
  distribution that must be supported, not the newest available.
- **Architecture:** Flutter has no cross-compile for Linux desktop. Every architecture shipped
  needs a builder of that architecture.

### To be checked

- ~~Where the app lives in the tree.~~ **Decided: `lib/` at the root**, one package named
  `sokar_frontend`, organization `org.fuin`, Linux the only enabled platform. A `packages/` split
  only pays for itself once something is genuinely shared, and nothing is yet. Revisit when a
  second consumer of the client code exists — not before.
- **Whether the client should be generated from the IDL after all.** The contract is machine
  readable and the daemon serves it, so a generator is possible. It becomes worth writing at the
  point where a hand-written client has drifted from the contract once.
