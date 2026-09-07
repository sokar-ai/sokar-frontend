import 'dart:async';

import 'mock_daemon.dart';

/// A machine, answered by a [MockDaemon] the way a real one would answer.
///
/// The point is that it **acts on what it is told**, rather than returning a fixed answer to each
/// method. A stand-in that says a task was removed and then goes on listing it makes a working
/// interface look like one where nothing happens — which is exactly how that was found, by hand,
/// after the tests were green.
///
/// Shared by `tool/mock_daemon.dart`, which is what a person opens the interface against, and by
/// the tests that hold this to the behaviour the interface is built on. One stand-in with one
/// behaviour: two would drift, and a drifted mock is worse than no mock.
class MockMachine {
  /// Puts a machine behind [daemon].
  ///
  /// [situation] is one of the names in [situations]. [pace] is how fast a launch prints — a real
  /// one takes minutes, a person watching wants to see the lines arrive, and a test wants neither.
  MockMachine(
    this.daemon, {
    this.situation = 'work',
    this.pace = const Duration(milliseconds: 400),
  }) {
    tasks = situation == 'empty' ? <Map<String, dynamic>>[] : _aMachineWithWorkOnIt();
    daemon.version = '0.1.0+mock';
    daemon.method('List', (_) => <String, dynamic>{'tasks': tasks});
    daemon.method('Agents', (_) => <String, dynamic>{
          'agents': <Map<String, dynamic>>[],
          'failures': <String, dynamic>{},
        });
    // pushes, not stream: Watch never ends, and a held-back stream would deliver every change one
    // change late.
    daemon.pushes('Watch', (_) async* {
      yield <String, dynamic>{'tasks': tasks};
      yield* _changes.stream;
    });
    daemon.stream('Start', (_) => _launch());
    daemon.method('Stop', _stop);
    // pushes, not stream: a log being followed does not end, and a held-back stream would
    // deliver every line one line late.
    daemon.pushes('Tail', _tail);
    daemon.method('Logs', _logs);
    daemon.method('Resume', _resume);

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
  }

  /// Situations worth opening the interface against, named for the situation rather than for the
  /// requirement that happened to need one.
  static const situations = <String, String>{
    'work': 'two projects, one of them with work stopped',
    'empty': 'a machine nothing has ever run on',
    'no-watch': 'a backend too old to have Watch, so nothing arrives by itself',
    'holds-work': 'a task that refuses to be removed because it holds unpushed commits',
    'nothing-knows': 'a task nothing can say anything about, which is refused too',
    'newer-outcome': 'an Outcome value added after this build shipped',
    'newer-interface': 'a backend serving Tasks2 beside the Tasks1 this build understands',
    'failing-start': 'a launch that prints for a while and then comes back non-zero',
  };

  /// The daemon answering for this machine.
  final MockDaemon daemon;

  /// Which situation this machine is in.
  final String situation;

  /// How fast a launch prints.
  final Duration pace;

  /// What is on the machine, as it goes over the wire.
  late List<Map<String, dynamic>> tasks;

  final _changes = StreamController<Map<String, dynamic>>.broadcast();

  /// Adds a task and tells every open `Watch` about it.
  void addTask(String name, String project) {
    tasks = <Map<String, dynamic>>[...tasks, _task(name, project)];
    _changes.add(<String, dynamic>{'tasks': tasks});
  }

  /// Stops answering.
  Future<void> close() => _changes.close();

  /// The logs this machine has.
  ///
  /// A real daemon checks a name against the files that are there and refuses one that is not.
  /// Nothing lists them — which is why the interface has to ask, and why this has to be able to
  /// refuse a name rather than only a method.
  static const logs = <String>{'agent.log', 'gate.log'};

  /// Which logs a task has. A task that was purged has none, and that is a normal answer.
  Map<String, dynamic> _logs(Map<String, dynamic> parameters) => <String, dynamic>{
        'logs': <Map<String, dynamic>>[
          for (final name in logs)
            <String, dynamic>{
              'name': name,
              'bytes': name == 'gate.log' ? 4096 : 182_311,
              'at': '2026-09-07T14:12:00Z',
            },
        ],
      };

  Stream<Map<String, dynamic>> _tail(Map<String, dynamic> parameters) async* {
    final log = parameters['log'];
    if (!logs.contains(log)) {
      throw MockRefusal('org.fuin.sokar.Tasks1.NoSuchLog', <String, dynamic>{
        'task': parameters['task'],
        'log': log,
      });
    }
    const red = '\u001B[31m';
    const green = '\u001B[32m';
    const plain = '\u001B[0m';
    final lines = log == 'gate.log'
        ? <String>[
            'gate: mirror at refs/sokar/incoming',
            'gate: waiting for a decision',
            '${green}gate: 2 commits accepted$plain',
          ]
        : <String>[
            'agent: reading the prompt',
            'agent: running the tests',
            '${red}agent: 1 test failed$plain',
            'agent: waiting',
          ];
    for (final line in lines) {
      if (pace > Duration.zero) await Future<void>.delayed(pace);
      yield <String, dynamic>{
        'lines': <String>[line],
      };
    }
  }

  Map<String, dynamic> _stop(Map<String, dynamic> parameters) {
    final answer = <String, dynamic>{
      'outcome': switch (situation) {
        'holds-work' => 'HOLDS_WORK',
        'nothing-knows' => 'NOTHING_KNOWS',
        'newer-outcome' => 'QUARANTINED',
        _ => 'STOPPED',
      },
      'work':
          situation == 'holds-work' ? '2 commits on refs/heads/fix-rounding' : '',
      'rescuedRef': '',
      'removed': situation != 'holds-work' && situation != 'nothing-knows',
      'helpers': 0,
      'surviving': situation == 'holds-work' ? 2 : 0,
      'detail': '',
      // Counted only when it was removed, and nothing else ever records that any of it existed.
      'discarded': 0,
    };
    // Purge and rescue are the caller having decided about what is held, so they get through.
    final insisted = parameters['purge'] == true ||
        parameters['rescue'] == true ||
        parameters['force'] == true;
    if (answer['removed'] == true || insisted) {
      answer['removed'] = true;
      answer['discarded'] = 128;
      if (insisted) answer['outcome'] = 'STOPPED';
      tasks = tasks.where((task) => task['name'] != parameters['task']).toList();
      _changes.add(<String, dynamic>{'tasks': tasks});
    }
    return answer;
  }

  Map<String, dynamic> _resume(Map<String, dynamic> parameters) {
    tasks = tasks
        .map((task) => task['name'] != parameters['task']
            ? task
            : <String, dynamic>{
                ...task,
                'running': true,
                'state': 'Up 1 second',
                'helpers': 1,
              })
        .toList();
    _changes.add(<String, dynamic>{'tasks': tasks});
    return <String, dynamic>{
      'outcome': situation == 'newer-outcome' ? 'QUARANTINED' : 'RESUMED',
      'started': 1,
      // Fewer started than recorded on purpose: a partial resume is worth seeing said out loud.
      'recorded': 2,
      'imageDrift': 'the image was rebuilt 20 minutes ago',
      'problems': <String>['gate helper did not come back'],
    };
  }

  Stream<Map<String, dynamic>> _launch() async* {
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
    final failing = situation == 'failing-start';
    for (final step in steps) {
      if (pace > Duration.zero) await Future<void>.delayed(pace);
      yield <String, dynamic>{'line': step};
    }
    if (failing) yield <String, dynamic>{'line': 'could not reach the registry'};
    yield <String, dynamic>{
      'container': 'sokar-checkout-shell',
      'exitCode': failing ? 1 : 0,
    };
  }

  static List<Map<String, dynamic>> _aMachineWithWorkOnIt() =>
      <Map<String, dynamic>>[
        _task('sokar-checkout-shell', 'checkout'),
        _task('sokar-checkout-migrate', 'checkout', running: false, helpers: 0),
        _task('sokar-billing-shell', 'billing', securityClass: 'offline', helpers: 1),
        // A container up with no helpers has lost its gate or its clearance watcher, which the
        // detail calls out. Worth having on screen while the frame is being looked at.
        _task('sokar-billing-audit', 'billing', helpers: 0),
        // A failed run is no longer swept away: a non-zero exit stops the container and leaves it
        // in place, workspace and logs intact, because the run worth looking at is the one that
        // went wrong. So a list has more exited tasks on it than it used to.
        _task('sokar-checkout-tests', 'checkout', running: false, helpers: 0),
      ];

  static Map<String, dynamic> _task(
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
        'state': running ? 'Up 4 minutes' : 'Exited (1) 12 minutes ago',
        'running': running,
        'helpers': helpers,
      };
}
