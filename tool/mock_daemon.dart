// Runs the mock backend on its own, so the interface can be worked on with no daemon.
// ignore_for_file: avoid_print - this is a command-line tool; printing is its output.
//
// Usage: dart tool/mock_daemon.dart [situation]
//
//   dart tool/mock_daemon.dart
//   SOKAR_SOCKET=<the path it prints> flutter run -d linux
//
// RETURN publishes a change to every open Watch. Events are driven by whoever is testing and
// never by a clock, which is the same rule the automated tests follow and for the same reason.
import 'dart:async';
import 'dart:io';

import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// Situations worth opening the interface against, named for the situation rather than for the
/// requirement that happened to need one.
const _situations = <String, String>{
  'work': 'two projects, one of them with work stopped',
  'empty': 'a machine nothing has ever run on',
  'no-watch': 'a backend too old to have Watch, so nothing arrives by itself',
  'holds-work': 'a task that refuses to be removed because it holds unpushed commits',
  'newer-outcome': 'an Outcome value added after this build shipped',
  'newer-interface': 'a backend serving Tasks2 beside the Tasks1 this build understands',
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
  daemon.stream(
    'Watch',
    (_) async* {
      yield <String, dynamic>{'tasks': tasks};
      yield* changes.stream;
    },
  );
  daemon.method('Stop', (_) => _stopped(situation));

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

  print('mock sokard — ${_situations[situation]}');
  print('');
  print('  SOKAR_SOCKET=${daemon.socketPath} flutter run -d linux');
  print('');
  print('  RETURN adds a task and pushes the change, ctrl-d stops');

  var added = 0;
  while (stdin.readLineSync() != null) {
    added++;
    tasks = <Map<String, dynamic>>[
      ...tasks,
      _task('sokar-checkout-fix-$added', 'checkout'),
    ];
    changes.add(<String, dynamic>{'tasks': tasks});
    print('published ${tasks.length} tasks');
  }

  await changes.close();
  await daemon.stop();
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
        'newer-outcome' => 'QUARANTINED',
        _ => 'STOPPED',
      },
      'work': situation == 'holds-work' ? '2 commits on refs/heads/fix-rounding' : '',
      'rescuedRef': '',
      'removed': situation == 'holds-work' ? false : true,
      'helpers': 0,
      'surviving': situation == 'holds-work' ? 2 : 0,
      'detail': '',
    };
