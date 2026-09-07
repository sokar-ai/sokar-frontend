// Runs the mock backend on its own, so the interface can be worked on with no daemon.
// ignore_for_file: avoid_print - this is a command-line tool; printing is its output.
//
// Usage: dart tool/mock_daemon.dart [situation]
//
//   dart tool/mock_daemon.dart
//   SOKAR_SOCKET=/tmp/sokar-mock.sock flutter run -d linux
//
// RETURN publishes a change to every open Watch. Events are driven by whoever is testing and
// never by a clock, which is the same rule the automated tests follow and for the same reason.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// Situations worth opening the interface against, named for the situation rather than for the
/// requirement that happened to need one.
const _situations = <String, String>{
  'work': 'two projects, one of them with work stopped',
  'empty': 'a machine nothing has ever run on',
  'no-watch': 'a backend too old to have Watch, so nothing arrives by itself',
  'holds-work': 'a task that refuses to be removed because it holds unpushed commits',
  'nothing-knows': 'a task nothing can say anything about, which is refused too',
  'newer-outcome': 'an Outcome value added after this build shipped',
  'newer-interface': 'a backend serving Tasks2 beside the Tasks1 this build understands',
  'failing-start': 'a launch that prints for a while and then comes back non-zero',
};

Future<void> main(List<String> args) async {
  final situation = args.isEmpty ? 'work' : args.first;
  if (!_situations.containsKey(situation)) {
    stderr.writeln('Unknown situation "$situation". One of:');
    _situations.forEach((name, what) => stderr.writeln('  ${name.padRight(16)} $what'));
    exitCode = 1;
    return;
  }

  final daemon = MockDaemon();
  await daemon.start();

  var tasks = situation == 'empty' ? <Map<String, dynamic>>[] : _aMachineWithWorkOnIt();
  final changes = StreamController<Map<String, dynamic>>.broadcast();

  daemon.version = '0.1.0+mock';
  daemon.method('List', (_) => <String, dynamic>{'tasks': tasks});
  daemon.method('Agents', (_) => <String, dynamic>{
        'agents': <Map<String, dynamic>>[],
        'failures': <String, dynamic>{},
      });
  // pushes, not stream: Watch never ends, and a held-back stream would deliver every change one
  // change late.
  daemon.pushes(
    'Watch',
    (_) async* {
      yield <String, dynamic>{'tasks': tasks};
      yield* changes.stream;
    },
  );
  daemon.method('Stop', (_) => _stopped(situation));
  daemon.method('Resume', (_) => <String, dynamic>{
        'outcome': situation == 'newer-outcome' ? 'QUARANTINED' : 'RESUMED',
        'started': 1,
        // Fewer started than recorded on purpose: a partial resume is worth seeing said out loud.
        'recorded': 2,
        'imageDrift': 'the image was rebuilt 20 minutes ago',
        'problems': <String>['gate helper did not come back'],
      });
  // stream, not pushes: a launch is finite and its last reply is the result rather than a line.
  daemon.stream('Start', (_) => _launch(failing: situation == 'failing-start'));

  switch (situation) {
    case 'no-watch':
      daemon.remove('Watch');
    case 'newer-interface':
      daemon.interfaces = const <String>[
        'org.varlink.service',
        'org.fuin.sokar.Tasks1',
        'org.fuin.sokar.Tasks2',
      ];
  }

  // The daemon picks a fresh temporary path every run, which makes the one instruction anybody
  // needs impossible to copy. A link at a stable name fixes that; a unix socket connects through
  // one unchanged.
  _forgetStableSocket();
  Link(_stableSocket).createSync(daemon.socketPath);

  print('mock sokard — ${_situations[situation]}');
  print('');
  print('  SOKAR_SOCKET=$_stableSocket flutter run -d linux');
  print('');
  print('  RETURN adds a task and pushes the change, ctrl-d stops');

  // Asynchronously, and that is not a style choice: stdin.readLineSync() blocks the isolate, so
  // a daemon that waited on it would accept a connection and then never answer a call. It looks
  // exactly like a hung backend, because it is one.
  var added = 0;
  final typing = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((_) {
    added++;
    tasks = <Map<String, dynamic>>[
      ...tasks,
      _task('sokar-checkout-fix-$added', 'checkout'),
    ];
    changes.add(<String, dynamic>{'tasks': tasks});
    print('published ${tasks.length} tasks');
  });
  await typing.asFuture<void>();

  await changes.close();
  await daemon.stop();
  _forgetStableSocket();
}

void _forgetStableSocket() {
  final link = Link(_stableSocket);
  if (link.existsSync()) link.deleteSync();
}

/// A name that does not move between runs, so the command to open the interface does not either.
const _stableSocket = '/tmp/sokar-mock.sock';

/// A launch, paced so it can be watched.
///
/// A delay here on purpose, and the one place in this repository where one is right: this is a
/// person watching a build, not a test. A test drives its own events, or it measures how fast the
/// machine is instead of what the interface does.
Stream<Map<String, dynamic>> _launch({required bool failing}) async* {
  const steps = <String>[
    'Resolving project.yml',
    'Reading the agent manifest',
    'Building the image (this is the slow bit)',
    '  layer 1/3',
    '  layer 2/3',
    '  layer 3/3',
    'Preparing the workspace',
    'Starting the gate',
  ];
  for (final step in steps) {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield <String, dynamic>{'line': step};
  }
  if (failing) {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield <String, dynamic>{'line': 'could not reach the registry'};
  }
  yield <String, dynamic>{
    'container': 'sokar-checkout-shell',
    'exitCode': failing ? 1 : 0,
  };
}

List<Map<String, dynamic>> _aMachineWithWorkOnIt() => <Map<String, dynamic>>[
      _task('sokar-checkout-shell', 'checkout'),
      _task('sokar-checkout-migrate', 'checkout', running: false, helpers: 0),
      _task('sokar-billing-shell', 'billing', securityClass: 'offline', helpers: 1),
      // A container up with no helpers has lost its gate or its clearance watcher, which the
      // detail calls out. Worth having on screen while the frame is being looked at.
      _task('sokar-billing-audit', 'billing', helpers: 0),
    ];

Map<String, dynamic> _task(
  String name,
  String project, {
  bool running = true,
  int helpers = 2,
  String securityClass = 'guarded',
}) =>
    <String, dynamic>{
      'name': name,
      'project': project,
      'securityClass': securityClass,
      'state': running ? 'Up 4 minutes' : 'Exited (0) 12 minutes ago',
      'running': running,
      'helpers': helpers,
    };

Map<String, dynamic> _stopped(String situation) => <String, dynamic>{
      'outcome': switch (situation) {
        'holds-work' => 'HOLDS_WORK',
        'nothing-knows' => 'NOTHING_KNOWS',
        'newer-outcome' => 'QUARANTINED',
        _ => 'STOPPED',
      },
      'work': situation == 'holds-work' ? '2 commits on refs/heads/fix-rounding' : '',
      'rescuedRef': '',
      'removed': situation != 'holds-work' && situation != 'nothing-knows',
      'helpers': 0,
      'surviving': situation == 'holds-work' ? 2 : 0,
      'detail': '',
    };
