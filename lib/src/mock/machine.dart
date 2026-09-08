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
/// the tests that hold this to the behavior the interface is built on. One stand-in with one
/// behavior: two would drift, and a drifted mock is worse than no mock.
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
          'agents': situation == 'no-agent'
              ? <Map<String, dynamic>>[]
              : <Map<String, dynamic>>[
                  <String, dynamic>{
                    'name': 'an-agent',
                    'label': 'An Agent',
                    'binary': '/usr/bin/an-agent',
                    'version': '2.4.0',
                    'from': '/usr/share/sokar/agents/an-agent.yml',
                    'allowedDomains': <String>['api.anthropic.com'],
                    'refusedDomains': <String>['telemetry.example.test'],
                    'artifacts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'url': 'https://example.test/an-agent-2.4.0.tar.gz',
                        'sha256':
                            '3b1f8e2a9c4d5067a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718',
                        'target': '/opt/an-agent',
                        'unverified': false,
                        'reason': '',
                      },
                    ],
                  },
                  <String, dynamic>{
                    'name': 'other-agent',
                    'label': 'Another Agent',
                    'binary': '/usr/bin/other-agent',
                    'version': '',
                    'from': '/etc/sokar/agents/other-agent.yml',
                    'allowedDomains': <String>['api.example.test'],
                    'refusedDomains': <String>[],
                    // Knowingly unverified, with the reason that makes it a decision rather than
                    // an oversight. The daemon refuses to build one with neither.
                    'artifacts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'url': 'https://example.test/other-agent-latest.tar.gz',
                        'sha256': '',
                        'target': '/opt/other-agent',
                        'unverified': true,
                        'reason': 'upstream publishes no digest for the rolling build',
                      },
                    ],
                  },
                ],
          // One that could not be read. Shown rather than dropped: missing from a list looks
          // exactly like never installed, and only one of those is worth fixing.
          'failures': <String, dynamic>{
            'broken-agent': 'its manifest could not be parsed',
          },
          // Installed and never started, because a copy in a more specific directory wins. Nothing
          // else in the product surfaces this, and a packaged agent hidden by a hand-placed copy
          // was found on a real machine the day the field landed.
          'shadowed': <Map<String, dynamic>>[
            <String, dynamic>{
              'path': '/usr/libexec/sokar/agents/an-agent',
              'usedInstead': '/home/somebody/.local/share/sokar/agents/an-agent',
            },
          ],
        });
    // pushes, not stream: Watch never ends, and a held-back stream would deliver every change one
    // change late.
    daemon.pushes('Watch', (_) async* {
      yield <String, dynamic>{'tasks': tasks};
      yield* _changes.stream;
    });
    daemon.stream('Start', _launch);
    daemon.method('Stop', _stop);
    // pushes, not stream: a log being followed does not end, and a held-back stream would
    // deliver every line one line late.
    daemon.pushes('Tail', _tail);
    daemon.method('Logs', _logs);
    daemon.method('Projects', _projects);
    daemon.method('Sets', _sets);
    daemon.method('Egress', _egress);
    daemon.method('SetEgress', _setEgress);
    daemon.method('WidenTask', _widenTask);
    daemon.method('Pending', _pending);
    daemon.method('Review', _review);
    daemon.method('Approve', _approve);
    daemon.method('Reject', _reject);
    // Prompts streams and only streams: answering it once would look like it worked and then
    // deliver nothing ever again.
    daemon.pushes('Prompts', (_) async* {
      // Anything raised before anybody was watching is handed over first. A real daemon has the
      // task blocked and waiting either way; without this a test would have to win a race that
      // says nothing about the interface.
      for (final asked in _raisedBeforeAnybodyWatched) {
        yield asked;
      }
      _raisedBeforeAnybodyWatched.clear();
      _watched = true;
      yield* _asking.stream;
    });
    daemon.method('Decide', _decide);
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
    'out-of-time': 'an unattended run killed by its own time limit, with its log kept',
    'no-agent': 'a run asked for when no agent is installed, which is a refusal not a failure',
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
  Future<void> close() async {
    await _changes.close();
    await _asking.close();
  }

  /// The logs this machine has.
  ///
  /// A real daemon checks a name against the files that are there and refuses one that is not.
  /// Nothing lists them — which is why the interface has to ask, and why this has to be able to
  /// refuse a name rather than only a method.
  static const logs = <String>{'agent.log', 'gate.log'};

  final _asking = StreamController<Map<String, dynamic>>.broadcast();
  final _raisedBeforeAnybodyWatched = <Map<String, dynamic>>[];
  bool _watched = false;

  void _raise(Map<String, dynamic> event) {
    if (_watched) {
      _asking.add(event);
    } else {
      _raisedBeforeAnybodyWatched.add(event);
    }
  }

  /// Raises a blocked connection, and gives back the question so it can be answered or expired.
  ///
  /// Driven by whoever is testing, never by a clock — the same rule the automated tests follow.
  Map<String, dynamic> blocks(String destination, {String task = 'sokar-checkout-shell'}) {
    final parts = destination.split(':');
    final asked = <String, dynamic>{
      'task': task,
      'key': 'tcp/$destination',
      'destination': parts.first,
      'protocol': 'tcp',
      'port': int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      'at': DateTime.now().toUtc().toIso8601String(),
      'prefix': 'egress/deny',
    };
    _raise(asked);
    return asked;
  }

  /// Lets a question run out, which is the one case nothing asks about again.
  void expires(Map<String, dynamic> asked) => _raise(<String, dynamic>{
        ...asked,
        'at': DateTime.now().toUtc().toIso8601String(),
        'prefix': '',
        'verdict': 'timeout',
      });

  Map<String, dynamic> _decide(Map<String, dynamic> parameters) {
    // The answer comes back on the same stream, which is also how a client sees the echo of its
    // own decision. It must not be applied twice.
    _raise(<String, dynamic>{
      'task': parameters['task'],
      'key': parameters['key'],
      'destination': parameters['address'],
      'protocol': 'tcp',
      'port': 0,
      'at': DateTime.now().toUtc().toIso8601String(),
      'prefix': '',
      'verdict': parameters['allow'] == true ? 'allow' : 'deny',
    });
    return <String, dynamic>{'ok': true};
  }

  /// What is waiting at the gate, by ref name. Approving or dropping one takes it out.
  final Map<String, Map<String, dynamic>> _waiting = <String, Map<String, dynamic>>{
    'refs/sokar/incoming/fix-rounding': <String, dynamic>{
      'name': 'refs/sokar/incoming/fix-rounding',
      'commit': '9a3c1f2',
      'subject': 'Round to the nearest penny, not away from zero',
      'waiting': '4 minutes',
      'at': '2026-09-07T14:12:00Z',
    },
    'refs/sokar/incoming/drop-dead-code': <String, dynamic>{
      'name': 'refs/sokar/incoming/drop-dead-code',
      'commit': '7f21b0e',
      'subject': 'Delete the retry loop nothing calls any more',
      'waiting': '26 minutes',
      'at': '2026-09-07T13:50:00Z',
    },
  };

  /// What was forwarded, and onto which branch, so a manual run can see it happened.
  final List<String> forwarded = <String>[];

  Map<String, dynamic> _pending(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        'mirror': '/srv/checkout/.sokar/mirror',
        'mode': 'gatekeeping',
        'seededFrom': '',
        'pending': _waiting.values.toList(),
      };

  Map<String, dynamic> _review(Map<String, dynamic> parameters) {
    final oneFile = parameters['name'] == 'refs/sokar/incoming/drop-dead-code';
    return <String, dynamic>{
      'diff': oneFile ? _deletionDiff : _changeDiff,
      'log': 'commit ${oneFile ? '7f21b0e' : '9a3c1f2'}\n'
          'Author: an agent <agent@sokar>\n\n'
          '    ${_waiting[parameters['name']]?['subject'] ?? ''}',
    };
  }

  Map<String, dynamic> _approve(Map<String, dynamic> parameters) {
    final name = '${parameters['name']}';
    if ('${parameters['branch']}'.isEmpty) {
      throw const MockRefusal('org.fuin.sokar.Tasks1.BranchRequired');
    }
    _waiting.remove(name);
    forwarded.add('$name -> ${parameters['branch']}');
    return <String, dynamic>{
      'forwarded': name,
      'branch': '${parameters['branch']}',
    };
  }

  Map<String, dynamic> _reject(Map<String, dynamic> parameters) {
    final name = '${parameters['name']}';
    _waiting.remove(name);
    return <String, dynamic>{'rejected': name};
  }

  /// The sets a project is using, by project file.
  final Set<String> _using = <String>{'dart-packages'};

  /// The sets installed here, scanned rather than fixed.
  static const _installed = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'dart-packages',
      'label': 'Dart packages',
      'domains': <String>['pub.dev', 'storage.googleapis.com'],
    },
    <String, dynamic>{
      'name': 'containers',
      'label': 'Container registries',
      'domains': <String>['registry.fedoraproject.org', 'quay.io', 'docker.io'],
    },
    <String, dynamic>{
      'name': 'forges',
      'label': 'Code forges',
      'domains': <String>['github.com', 'gitlab.com'],
    },
  ];

  Map<String, dynamic> _sets(Map<String, dynamic> parameters) => <String, dynamic>{
        'sets': _installed,
        'locations': <String>['/etc/sokar/egress.d', '/usr/share/sokar/egress.d'],
      };

  Map<String, dynamic> _egress(Map<String, dynamic> parameters) => <String, dynamic>{
        // In the order the sources granted them. The first grant wins, so this order is the
        // answer to "where did this host come from" and must not be sorted.
        'hosts': <Map<String, dynamic>>[
          <String, dynamic>{'host': 'api.anthropic.com', 'origin': 'agent an-agent'},
          <String, dynamic>{'host': 'github.com', 'origin': 'upstream'},
          for (final name in _using)
            for (final host in _domainsOf(name))
              <String, dynamic>{'host': host, 'origin': 'set $name'},
        ],
        'refused': <String>['telemetry.example.test'],
      };

  Map<String, dynamic> _setEgress(Map<String, dynamic> parameters) {
    final adding = (parameters['addSets'] as List?)?.cast<String>() ?? <String>[];
    final removing = (parameters['removeSets'] as List?)?.cast<String>() ?? <String>[];
    final preview = parameters['dryRun'] == true;

    for (final name in <String>[...adding, ...removing]) {
      if (!_installed.any((set) => set['name'] == name)) {
        return <String, dynamic>{
          'outcome': 'NO_SUCH_SET',
          'opens': <Map<String, dynamic>>[],
          'closes': <Map<String, dynamic>>[],
          'cost': '',
          'detail': '$name is not installed on this machine',
        };
      }
    }

    final opens = <Map<String, dynamic>>[
      for (final name in adding)
        for (final host in _domainsOf(name))
          <String, dynamic>{'host': host, 'origin': 'set $name'},
    ];
    final closes = <Map<String, dynamic>>[
      for (final name in removing)
        for (final host in _domainsOf(name))
          <String, dynamic>{'host': host, 'origin': 'set $name'},
    ];
    if (!preview) {
      _using
        ..addAll(adding)
        ..removeAll(removing);
    }
    return <String, dynamic>{
      'outcome': preview ? 'PREVIEWED' : 'CHANGED',
      'opens': opens,
      'closes': closes,
      // Filled only when *this* change makes a forge reachable for a guarded project, and never
      // repeated on a later edit.
      'cost': adding.contains('forges')
          ? 'the gate now rests on the container holding no credential rather than on the '
              'host being unreachable'
          : '',
      'detail': '',
    };
  }

  /// What each running task has been let reach beyond what its project declares.
  ///
  /// Kept, because the point of this stand-in is to act: a second call asking for the same name
  /// must answer `NO_CHANGE`, and a widened task must go on being widened.
  final Map<String, Set<String>> _granted = <String, Set<String>>{};

  /// Lets a running task reach names it could not reach before.
  ///
  /// Everything here is a state a real daemon produces and none of it is canned: whether the
  /// container is up, what class its project runs under, whether that project has a file to write
  /// to, and what it could already reach.
  Map<String, dynamic> _widenTask(Map<String, dynamic> parameters) {
    final name = parameters['task'] as String? ?? '';
    final asked = (parameters['domains'] as List?)?.cast<String>() ?? <String>[];
    final scope = parameters['scope'] as String? ?? '';
    final preview = parameters['dryRun'] == true;

    // No default, and the daemon will not invent one: this run and this project are different
    // intentions and choosing between them is not the daemon's to do.
    if (scope.isEmpty) throw const MockRefusal('org.fuin.sokar.Tasks1.ScopeRequired');

    final task = tasks.firstWhere(
      (each) => each['name'] == name,
      orElse: () => const <String, dynamic>{},
    );
    if (task.isEmpty || task['running'] != true) {
      return _widened('NOT_RUNNING', detail: 'there is no running container called $name');
    }
    if (task['securityClass'] == 'offline') {
      return _widened('REFUSED_BY_CLASS',
          detail: "an offline project's tasks reach nothing");
    }

    // In the order asked for, and only what it does not have already.
    final already = _granted[name] ?? const <String>{};
    final opens = <String>[for (final host in asked) if (!already.contains(host)) host];
    if (opens.isEmpty) {
      return _widened('NO_CHANGE', detail: 'it can reach all of that already');
    }
    if (preview) return _widened('PREVIEWED', opens: opens);

    _granted.putIfAbsent(name, () => <String>{}).addAll(opens);

    // The run was widened either way. Whether the file was written is the other half, and a
    // project whose file has moved is the case where the two answers differ.
    final file = _fileOf(task['project'] as String? ?? '');
    if (scope == 'RUN_AND_PROJECT' && file.isEmpty) {
      return _widened('NO_PROJECT_FILE',
          opens: opens,
          detail: 'the run can reach it; no project file is recorded, so nothing was written');
    }
    return _widened('WIDENED',
        opens: opens, persisted: scope == 'RUN_AND_PROJECT');
  }

  static Map<String, dynamic> _widened(
    String outcome, {
    List<String> opens = const <String>[],
    bool persisted = false,
    String detail = '',
  }) =>
      <String, dynamic>{
        'outcome': outcome,
        'opens': opens,
        'persisted': persisted,
        'detail': detail,
      };

  String _fileOf(String project) {
    final projects = (_projects(const <String, dynamic>{})['projects']!
        as List<Map<String, dynamic>>);
    return projects.firstWhere(
          (each) => each['name'] == project,
          orElse: () => const <String, dynamic>{'file': ''},
        )['file'] as String? ??
        '';
  }

  static List<String> _domainsOf(String name) => <String>[
        ...(_installed.firstWhere((set) => set['name'] == name,
                orElse: () => const <String, dynamic>{'domains': <String>[]})['domains']
            as List<String>),
      ];

  /// Every project on the machine, assembled the way the daemon assembles it.
  ///
  /// `never-run` is here on purpose: a project with no tasks, which a client deriving projects
  /// from the task list could never show. `no-file` is the other state worth having — listed, and
  /// nothing can act on it.
  Map<String, dynamic> _projects(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        'projects': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'checkout',
            'securityClass': 'guarded',
            'file': '/srv/checkout/project.yml',
            'mirror': '/srv/checkout/.sokar/mirror',
            'prepared': true,
            'behind': 3,
            'behindMeasured': DateTime.now()
                .toUtc()
                .subtract(const Duration(minutes: 20))
                .toIso8601String(),
            'behindReason': 'MEASURED',
            'behindDetail': '',
            'pending': _waiting.length,
            'tasks': tasks.where((task) => task['project'] == 'checkout').length,
            'running': tasks
                .where((task) => task['project'] == 'checkout' && task['running'] == true)
                .length,
          },
          <String, dynamic>{
            'name': 'billing',
            'securityClass': 'offline',
            'file': '/srv/billing/project.yml',
            'mirror': '',
            'prepared': true,
            'behind': 0,
            'behindMeasured': '',
            // An offline project reaches nothing, so nothing was tried. Distinct from zero.
            'behindReason': 'OFFLINE',
            'behindDetail': '',
            'pending': 0,
            'tasks': tasks.where((task) => task['project'] == 'billing').length,
            'running': tasks
                .where((task) => task['project'] == 'billing' && task['running'] == true)
                .length,
          },
          <String, dynamic>{
            'name': 'never-run',
            'securityClass': '',
            'file': '/srv/never-run/project.yml',
            'mirror': '',
            // Nothing has run here, so no image was ever built.
            'prepared': false,
            'behind': 0,
            'behindMeasured': '',
            'behindReason': 'NEVER_CHECKED',
            'behindDetail': '',
            'pending': 0,
            'tasks': 0,
            'running': 0,
          },
          <String, dynamic>{
            'name': 'moved-away',
            'securityClass': 'guarded',
            'file': '',
            'mirror': '/srv/moved/.sokar/mirror',
            'prepared': true,
            'behind': 0,
            'behindMeasured': DateTime.now()
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
            'behindReason': 'FAILED',
            'behindDetail': 'the upstream refused the connection',
            'pending': 1,
            'tasks': tasks.where((task) => task['project'] == 'moved-away').length,
            'running': tasks
                .where((task) => task['project'] == 'moved-away' && task['running'] == true)
                .length,
          },
        ],
      };

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

  /// Brings a container up, and — when a prompt is given — runs the agent in it.
  ///
  /// The two are different lengths of call, which is the whole point of the change that added
  /// `prompt`: without one this ends when the container is up, with one it lasts as long as the
  /// run and the agent's own output arrives as it is produced.
  Stream<Map<String, dynamic>> _launch(Map<String, dynamic> parameters) async* {
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
    final prompt = parameters['prompt'] as String? ?? '';
    // The backend's own rule, not this one's: a prompt means UNATTENDED unless something else was
    // asked for, and nothing without a prompt is unattended.
    final mode = parameters['mode'] as String? ??
        (prompt.isEmpty ? 'SHELL' : 'UNATTENDED');

    for (final step in steps) {
      if (pace > Duration.zero) await Future<void>.delayed(pace);
      yield <String, dynamic>{'line': step};
    }
    if (failing) yield <String, dynamic>{'line': 'could not reach the registry'};
    if (failing || prompt.isEmpty) {
      yield <String, dynamic>{
        'container': 'sokar-checkout-shell',
        'exitCode': failing ? 1 : 0,
      };
      return;
    }

    // No agent installed is a refusal, not a failed run: nothing ran and there is no log.
    if (situation == 'no-agent') {
      yield <String, dynamic>{'container': '', 'exitCode': 69};
      return;
    }

    // Raw log, the same text `Tail` serves for `task.log`. The agent's own formatting is made in
    // the CLI process and never reaches a socket.
    for (final line in <String>[
      'agent: $prompt',
      'agent: reading lib/money.dart',
      'agent: editing lib/money.dart',
      'agent: running the tests',
    ]) {
      if (pace > Duration.zero) await Future<void>.delayed(pace);
      yield <String, dynamic>{'line': line};
    }

    final container = parameters['task'] as String? ?? 'sokar-checkout-run';
    if (situation == 'out-of-time') {
      // Killed by its own limit. The log is kept, which is why the lines above still stand.
      yield <String, dynamic>{'container': container, 'exitCode': 124};
      return;
    }

    // The run is listed afterwards, carrying what it was asked to do — which is what continuing
    // it with a new prompt reads back.
    tasks = <Map<String, dynamic>>[
      ...tasks,
      _task(container, (parameters['project'] as String? ?? '').contains('billing')
              ? 'billing'
              : 'checkout',
          running: false,
          helpers: 0,
          activity: 'DEAD',
          mode: mode,
          agent: parameters['agent'] as String? ?? 'an-agent',
          prompt: prompt),
    ];
    _changes.add(<String, dynamic>{'tasks': tasks});
    yield <String, dynamic>{'container': container, 'exitCode': 0};
  }

  static const _changeDiff = '''
diff --git a/lib/money.dart b/lib/money.dart
index 1a2b3c4..5d6e7f8 100644
--- a/lib/money.dart
+++ b/lib/money.dart
@@ -12,7 +12,7 @@ class Money {
   final double value;
 
   int get pennies {
-    return (value * 100).ceil();
+    return (value * 100).round();
   }
 }
diff --git a/test/money_test.dart b/test/money_test.dart
--- a/test/money_test.dart
+++ b/test/money_test.dart
@@ -4,3 +4,7 @@ void main() {
     expect(Money(1.005).pennies, 101);
   });
+
+  test('rounds down below the half', () {
+    expect(Money(1.004).pennies, 100);
+  });
 }
''';

  static const _deletionDiff = '''
diff --git a/lib/retry.dart b/lib/retry.dart
deleted file mode 100644
--- a/lib/retry.dart
+++ /dev/null
@@ -1,5 +0,0 @@
-Future<void> retry(Future<void> Function() what) async {
-  for (var attempt = 0; attempt < 3; attempt++) {
-    try { await what(); return; } on Exception { /* again */ }
-  }
-}
''';

  static List<Map<String, dynamic>> _aMachineWithWorkOnIt() =>
      <Map<String, dynamic>>[
        // One of each, because the difference between them is what F22 exists for and a
        // machine with only working tasks on it proves nothing.
        _task('sokar-checkout-shell', 'checkout',
            activity: 'WAITING',
            waitingFor: 'api.example.test:443',
            minutesAgo: 6),
        _task('sokar-checkout-migrate', 'checkout', running: false, helpers: 0),
        _task('sokar-billing-shell', 'billing',
            securityClass: 'offline',
            helpers: 1,
            activity: 'IDLE',
            mode: 'SHELL',
            minutesAgo: 47),
        // A container up with no helpers has lost its gate or its clearance watcher, which the
        // detail calls out. Worth having on screen while the frame is being looked at.
        // A terminal is attached to this one, so nothing on this side can see what it is doing.
        // Started with enforcement off: nothing will ever be asked about what it reaches, which
        // is a choice somebody made and the interface has to show.
        _task('sokar-billing-audit', 'billing',
            helpers: 0,
            activity: 'UNKNOWN',
            mode: 'AGENT',
            clearance: 'off'),
        // A failed run is no longer swept away: a non-zero exit stops the container and leaves it
        // in place, workspace and logs intact, because the run worth looking at is the one that
        // went wrong. So a list has more exited tasks on it than it used to.
        _task('sokar-checkout-tests', 'checkout', running: false, helpers: 0),
        // Running, in a project whose file nothing can find any more. Widening its run works and
        // writing to its project does not, which is the one outcome most likely to be read as a
        // failure when it is not.
        _task('sokar-moved-work', 'moved-away'),
      ];

  static Map<String, dynamic> _task(
    String name,
    String project, {
    bool running = true,
    int helpers = 2,
    String securityClass = 'guarded',
    String activity = 'WORKING',
    String waitingFor = '',
    String mode = 'UNATTENDED',
    String agent = 'an-agent',
    int minutesAgo = 4,
    String clearance = 'prompt',
    String? prompt,
  }) =>
      <String, dynamic>{
        'name': name,
        'project': project,
        'securityClass': securityClass,
        'state': running ? 'Up $minutesAgo minutes' : 'Exited (1) 12 minutes ago',
        'running': running,
        'helpers': helpers,
        'agent': agent,
        'mode': mode,
        'prompt': prompt ??
            (mode == 'UNATTENDED'
                ? 'Fix the rounding in Money.pennies and add a test for it'
                : ''),
        'branch': 'refs/sokar/incoming/$name',
        'since': DateTime.now()
            .toUtc()
            .subtract(Duration(minutes: minutesAgo))
            .toIso8601String(),
        'activity': running ? activity : 'DEAD',
        'waitingFor': waitingFor,
        'clearance': clearance,
      };
}
