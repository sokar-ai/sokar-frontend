# sokar-frontend

The interface for [Sokar](https://github.com/fuinorg/sokar), in Flutter.

Sokar runs AI coding agents in locked-down containers: no network except what a project
declares, no credential the agent can read, and nothing leaves the machine without somebody
approving it. Everything it can do is reachable from a CLI today. This is the interface that
makes it reachable without one.

## Start here

1. **[Backend API](doc/Backend-API.md)** — how to talk to the daemon. One unix socket, JSON
   objects separated by NUL bytes, no client library. It also covers reaching a Sokar on another
   machine, which is the same code and a different socket path, and the rules for staying
   compatible with a backend older than this build.
2. **[Requirements](requirements/README.md)** — what must be true for a person using it, in the
   order to build it. Each file carries its own acceptance criteria, so it can be judged done
   rather than discussed. [Design](requirements/design.md) says what it is built out of.
3. **[What the contract does not yet cover](doc/Contract-Gaps.md)** — roughly half the
   requirements have no backend method behind them yet, and which half is not obvious.
4. **[AGENT.md](AGENT.md)** — the working rules: how to talk to the backend, how to stay
   compatible with an older one, how this is tested, built and packaged.

To see what a running backend offers, with a daemon up:

```
dart tool/contract.dart
```

## Build and test

Needs the Flutter SDK and the Linux desktop toolchain — `clang`, `cmake`, `ninja`, `pkg-config`,
`libgtk-3-dev`. `flutter doctor -v` says whether they are all there. **No JDK, ever**, and no
daemon, no podman and no container runtime: the whole suite runs against a mock.

```
flutter pub get
dart run build_runner build     # regenerates the tests from test/features/*.feature
dart analyze                    # must stay at "No issues found!"
flutter test
flutter build linux --release   # bundle in build/linux/x64/release/bundle
```

With a real `sokard` running, one more suite checks that this client still agrees with it — the
only test that can, and skipped when there is nothing to talk to:

```
SOKAR_SOCKET=$XDG_RUNTIME_DIR/sokar/sokard.sock flutter test test/client/live_daemon_test.dart
```

`dart analyze`, never `flutter analyze` — the reason is in [AGENT.md](AGENT.md). Run
`build_runner` after adding or editing a `.feature` file; the generated `_test.dart` beside it is
committed, and CI fails on a diff.

### Seeing it run, with no backend at all

The interface needs a daemon to show anything, and the mock is one — a real unix socket speaking
real varlink, which the client cannot tell from `sokard`. In two terminals:

```
dart tool/mock_daemon.dart                              # leave it running
SOKAR_SOCKET=/tmp/sokar-mock.sock flutter run -d linux
```

Pressing RETURN in the first terminal adds a task and pushes the change, so live updates can be
watched arriving. `Ctrl+K` → *Check that work can start here* runs a long operation against the
mock; `Ctrl+O` shows everything this session has run. The mock's tasks have `agent.log` and
`gate.log` to read — any other name is refused, the way a real daemon refuses one. Other situations to open it against, none of which a real daemon can be asked
for on demand:

| | |
|---|---|
| `dart tool/mock_daemon.dart empty` | a machine nothing has ever run on |
| `dart tool/mock_daemon.dart no-watch` | a backend too old for `Watch`, so nothing arrives by itself |
| `dart tool/mock_daemon.dart holds-work` | work that refuses to be removed because it holds unpushed commits |
| `dart tool/mock_daemon.dart nothing-knows` | work nothing can say anything about, which is refused too |
| `dart tool/mock_daemon.dart newer-outcome` | an `Outcome` added after this build shipped |
| `dart tool/mock_daemon.dart newer-interface` | a backend serving `Tasks2` beside the `Tasks1` this build understands |
| `dart tool/mock_daemon.dart failing-start` | a launch that prints for a while and then comes back non-zero |

`SOKAR_SOCKET` is how the interface is pointed at anything but the local daemon — the mock, or a
socket forwarded from another machine. It is a stopgap until
[F20](requirements/F20-Access-From-Elsewhere.md) gives a person a way to choose.

### On a build server

One run, two reports — the XML for the build server's own test tab, the HTML to publish as an
artifact somebody can open:

```
flutter test --machine > build/test-results.json
dart tool/test_report.dart                    # build/test-report.html
tojunit < build/test-results.json > build/test-results.xml
```

`tojunit` comes from `junitreport` (`dart pub global activate junitreport`), which puts it in
`$HOME/.pub-cache/bin` — add that to `PATH`. The HTML report needs nothing but `dart`.

Every feature names one requirement on its `Feature` line, and that becomes the JUnit group — so
**both reports are a per-requirement traceability matrix**. The HTML one goes further and reads
`requirements/` as well, so it lists the requirements *no scenario names yet*: a matrix that only
shows what was tested cannot answer the question somebody opens it to ask.

`dart tool/test_report.dart` exits non-zero when anything failed, so it can gate a build on its
own. It is one self-contained file with no external stylesheet, script or font — an artifact is
downloaded and opened from disk, where anything it had to fetch would be missing.

Passing is not the same as covered: a requirement with one shallow scenario shows as green as one
with twelve, and the report says so on its own face.

## What this is not

It is not a wrapper around the CLI. The daemon serves the domain directly, and an interface that
shelled out to `sokar` would be a second implementation of every refusal the product makes — the
ones that stop work being destroyed.
