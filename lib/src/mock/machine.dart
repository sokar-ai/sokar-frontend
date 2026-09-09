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
                    // What its commits are attributed to, which is what tells somebody looking at
                    // one whether an agent or a person wrote it.
                    'commitsAs': <String, dynamic>{
                      'name': 'An Agent',
                      'email': 'an-agent@sokar.invalid',
                    },
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
                    // Installed by a Sokar older than the field: absent, which is a state to
                    // render rather than a blank to fill in.
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
    daemon.method('Panic', _panic);
    daemon.method('DeleteProject', _deleteProject);
    daemon.method('Doctor', _doctor);
    daemon.method('Providers', _providers);
    daemon.method('ImportCredential', _importCredential);
    // Which node this is. Random per mock instance, so two mocks are two nodes and one mock
    // reached twice is one — which is the thing a client has to be able to tell.
    daemon.method('Node', (_) => <String, dynamic>{'id': _nodeId});
    daemon.method('Backups', _backups);
    daemon.method('DeleteBackup', _deleteBackup);
    daemon.method('RestoreBackup', _restoreBackup);
    daemon.method('SyncUpstream', _syncUpstream);
    daemon.method('CreateProject', _createProject);
    daemon.method('NarrowTask', _narrowTask);
    daemon.method('SetClearance', _setClearance);
    daemon.stream('Prepare', _prepare);
    daemon.method('Label', _label);
    daemon.method('CanStart', _canStart);
    daemon.method('Credentials', _credentials);
    daemon.method('Lock', _lock);

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
    'helper-survives': 'an emergency stop that leaves a helper running, to be killed by hand',
    'vault-locked': 'a vault nothing can read, so nothing can say what it holds',
    'no-credential': 'a vault with no credential for the provider a run would use',
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
  ///
  /// **The name is the ref *under* `refs/sokar/incoming/`, never the whole ref** — the contract
  /// says so and `Review`, `Approve` and `Reject` take the short form. This served whole refs
  /// until 2026-09-08, which is a fixture describing something the daemon cannot produce.
  ///
  /// `migrate` belongs to a task on this machine and `drop-dead-code` does not, deliberately:
  /// several containers over time share one ref, so a ref whose container is gone is an ordinary
  /// state rather than a broken one.
  final Map<String, Map<String, dynamic>> _waiting = <String, Map<String, dynamic>>{
    'migrate': <String, dynamic>{
      'name': 'migrate',
      'commit': '9a3c1f2',
      'subject': 'Round to the nearest penny, not away from zero',
      'waiting': '4 minutes',
      'at': '2026-09-07T14:12:00Z',
    },
    'drop-dead-code': <String, dynamic>{
      'name': 'drop-dead-code',
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

  /// Sets or clears the caption a task reads by.
  ///
  /// It acts: the caption really lands on the task, and **nothing about the identity moves** — the
  /// container name, and with it the gate ref and the log files, read exactly as before. A
  /// stand-in that answered `LABELLED` and went on showing the old caption would make a working
  /// interface look like one where nothing happens.
  Map<String, dynamic> _label(Map<String, dynamic> parameters) {
    final name = parameters['task'] as String? ?? '';
    final caption = (parameters['label'] as String? ?? '').trim();
    final task = tasks.firstWhere((each) => each['name'] == name,
        orElse: () => const <String, dynamic>{});
    if (task.isEmpty) {
      return <String, dynamic>{'outcome': 'NOT_A_TASK', 'label': ''};
    }
    tasks = <Map<String, dynamic>>[
      for (final each in tasks)
        if (each['name'] == name)
          <String, dynamic>{...each, 'label': caption}
        else
          each,
    ];
    _changes.add(<String, dynamic>{'tasks': tasks});
    return <String, dynamic>{
      'outcome': caption.isEmpty ? 'CLEARED' : 'LABELLED',
      'label': caption,
    };
  }

  /// Whether the store is open. Shutting it really does shut it, and the listing goes with it —
  /// a stand-in that answered *shut* and went on listing names would hide the one distinction
  /// this screen exists to draw.
  bool _open = true;

  Map<String, dynamic> _credentials(Map<String, dynamic> parameters) => <String, dynamic>{
        'vault': '/home/somebody/.local/share/sokar/vault.bin',
        'exists': true,
        // Names, kinds and lengths. **Never a value.**
        'credentials': _open || situation == 'vault-locked'
            ? <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'a-provider',
                  'type': 'api-key',
                  'characters': 108,
                },
              ]
            : <Map<String, dynamic>>[],
        // An unlocked store holding nothing answers true; only a shut one answers false.
        'readable': _open && situation != 'vault-locked',
      };

  Map<String, dynamic> _lock(Map<String, dynamic> parameters) {
    final wasOpen = _open;
    _open = false;
    return <String, dynamic>{
      'keyring': true,
      'wasCached': wasOpen,
      // A running task's proxy read the secret at start and holds it where locking cannot reach.
      'holding': tasks.where((task) => task['running'] == true).length,
    };
  }

  /// Whether work can start, answered before anything is created.
  ///
  /// It acts on the situation rather than answering canned: the three outcomes that mean
  /// different actions are each reachable, and `credential` names the key that was looked for
  /// rather than the one that ought to apply.
  Map<String, dynamic> _canStart(Map<String, dynamic> parameters) {
    final agent = parameters['agent'] as String? ?? '';
    if (situation == 'no-agent') {
      return _readiness('NO_AGENT', detail: 'nothing is installed here to run work with');
    }
    if (situation == 'vault-locked' || !_open) {
      return _readiness('VAULT_LOCKED',
          agent: agent, detail: 'the vault is locked, so nothing can say what it holds');
    }
    if (situation == 'no-credential') {
      return _readiness('CREDENTIAL_MISSING',
          agent: agent,
          provider: 'a-provider',
          // The provider's name, which is what is actually looked up — an older vault answers
          // under the agent's own name, and naming the wrong one reports a key missing from a
          // vault that has it.
          credential: 'a-provider',
          detail: "the vault holds no credential for 'a-provider'");
    }
    if (agent == 'other-agent') {
      return _readiness('NO_PROVIDER_CHOSEN',
          agent: agent, detail: 'names no default provider, so one has to be chosen');
    }
    return _readiness('READY',
        ready: true, agent: agent.isEmpty ? 'an-agent' : agent, provider: 'a-provider',
        credential: 'a-provider');
  }

  static Map<String, dynamic> _readiness(
    String outcome, {
    bool ready = false,
    String agent = '',
    String provider = '',
    String credential = '',
    String detail = '',
  }) =>
      <String, dynamic>{
        'ready': ready,
        'outcome': outcome,
        'agent': agent,
        'provider': provider,
        'credential': credential,
        'detail': detail,
      };

  /// Stops every running task at once, and never removes anything.
  ///
  /// It acts: the tasks really do stop being listed as running, and `Resume` brings them back —
  /// a stand-in that answered *stopped* and went on listing them as up is how a working interface
  /// looks like one where nothing happens.
  /// Removes what Sokar built for a project, or says what it would remove.
  ///
  /// **It refuses rather than decides**, on the same two things the daemon does: a ref nobody has
  /// reviewed, and a task that is up. `keeps` names the operator's own file so a confirmation can
  /// say it survives without this end having to know which things are Sokar's.
  Map<String, dynamic> _deleteProject(Map<String, dynamic> parameters) {
    final name = parameters['project'] as String? ?? '';
    final preview = parameters['dryRun'] == true;
    final force = parameters['force'] == true;
    final its = tasks.where((task) => task['project'] == name).toList();

    final known = (_projects(const <String, dynamic>{})['projects']! as List)
        .whereType<Map<String, dynamic>>()
        .any((project) => project['name'] == name);
    if (!known) {
      return <String, dynamic>{
        'outcome': 'NO_SUCH_PROJECT',
        'removes': <Map<String, dynamic>>[],
        'keeps': <String>[],
        'unreviewed': <String>[],
        'running': <String>[],
        'detail': 'nothing here knows that project',
      };
    }

    // What a person recognizes, in the order somebody would think of them.
    final removes = <Map<String, dynamic>>[
      <String, dynamic>{'kind': 'MIRROR', 'what': '/srv/$name/.sokar/mirror'},
      <String, dynamic>{'kind': 'IMAGE', 'what': 'sokar/$name:latest'},
      <String, dynamic>{'kind': 'BUILD', 'what': '/srv/$name/.sokar/build'},
      <String, dynamic>{'kind': 'REGISTRY', 'what': name},
      for (final task in its)
        <String, dynamic>{'kind': 'TASK', 'what': task['name']},
    ];
    // The gate is the checkout project's, so only that one can hold unreviewed work here.
    final unreviewed = name == 'checkout' ? _waiting.keys.toList() : <String>[];
    final running = <String>[
      for (final task in its)
        if (task['running'] == true) task['name'] as String,
    ];

    String outcome;
    if (preview) {
      outcome = 'PREVIEWED';
    } else if (!force && unreviewed.isNotEmpty) {
      outcome = 'HOLDS_WORK';
    } else if (!force && running.isNotEmpty) {
      outcome = 'TASKS_RUNNING';
    } else {
      outcome = 'DELETED';
      tasks = <Map<String, dynamic>>[
        for (final task in tasks)
          if (task['project'] != name) task,
      ];
      // Gone from the listing as well as from the task list: a project still on screen after it
      // was removed is the one reading that would send somebody looking for what is left of it.
      _removedProjects.add(name);
      _changes.add(<String, dynamic>{'tasks': tasks});
    }

    return <String, dynamic>{
      'outcome': outcome,
      'removes': removes,
      // Named by the contract, because a client cannot know which things are Sokar's — and one
      // that guessed would sooner or later name the operator's own file among the casualties.
      'keeps': <String>['/srv/$name/project.yml'],
      'unreviewed': unreviewed,
      'running': running,
      'detail': outcome == 'HOLDS_WORK' || outcome == 'TASKS_RUNNING'
          ? 'nothing was removed'
          : '',
    };
  }

  Map<String, dynamic> _panic(Map<String, dynamic> parameters) {
    final preview = parameters['dryRun'] == true;
    final stopping = tasks.where((task) => task['running'] == true).toList();

    if (!preview) {
      tasks = <Map<String, dynamic>>[
        for (final task in tasks)
          if (task['running'] != true)
            task
          else
            <String, dynamic>{
              ...task,
              'running': false,
              // Stopped, not removed: the state directory, the workspace and the logs are all
              // still there, which is what makes Resume possible.
              'state': 'Exited (143) 0 seconds ago',
              'activity': 'DEAD',
              'helpers': 0,
            },
      ];
      _changes.add(<String, dynamic>{'tasks': tasks});
    }

    return <String, dynamic>{
      'tasks': <Map<String, dynamic>>[
        for (final task in stopping)
          <String, dynamic>{
            'name': task['name'],
            'helpers': task['helpers'],
            // A dry run attempts nothing, so nothing can have survived it — which is not the
            // same as nothing surviving, and must never be drawn as though it were.
            'surviving': situation == 'helper-survives' &&
                    !preview &&
                    task['name'] == 'sokar-checkout-shell'
                ? <String>['sokar-checkout-shell-gate (pid 4711)']
                : <String>[],
          },
      ],
      // A helper that outlived its stop. Named rather than counted, because somebody has to kill
      // it by hand — and a machine where this is empty proves nothing about one where it is not.
      'surviving': situation == 'helper-survives' && !preview
          ? <String>['sokar-checkout-shell-gate (pid 4711)']
          : <String>[],
      'previewed': preview,
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
  /// Creates a project file, having checked the answers against this machine first.
  ///
  /// **The checking is what a client cannot do**: whether a class is spelled right, whether a set
  /// exists here, whether the name survives becoming an image tag and an nftables set name.
  Map<String, dynamic> _createProject(Map<String, dynamic> parameters) {
    final file = parameters['file'] as String? ?? '';
    final name = parameters['name'] as String? ?? '';
    final klass = parameters['securityClass'] as String? ?? '';
    final baseImage = parameters['baseImage'] as String? ?? '';
    final upstream = parameters['upstream'] as String? ?? '';
    final sets = (parameters['sets'] as List?)?.cast<String>() ?? <String>[];
    final preview = parameters['dryRun'] == true;

    final problems = <Map<String, dynamic>>[
      if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(name))
        _problem('name', 'a project name becomes an image tag and an nftables set name, so it '
            'may hold only lower-case letters, digits and dashes', fatal: true),
      if (!const <String>['offline', 'guarded', 'online'].contains(klass))
        _problem('securityClass', '"$klass" is not a class this machine knows', fatal: true),
      if (klass == 'online' && upstream.isEmpty)
        _problem('upstream', 'an online project pushes to its upstream directly, so it needs one',
            fatal: true),
      for (final set in sets)
        if (!_knownSets.contains(set))
          _problem('sets', 'no egress set called "$set" is installed on this machine',
              fatal: true),
      // Worth showing and not worth blocking on: it will simply be pulled.
      if (baseImage.isNotEmpty && !baseImage.startsWith('ubuntu:'))
        _problem('baseImage', 'not on this machine yet, so the first build will pull it',
            fatal: false),
    ];
    final blocked = problems.any((each) => each['fatal'] == true);

    // A refusal and never an overwrite: the file may be somebody's whole configuration.
    final exists = _createdProjects.contains(file) ||
        _everyProject.any((each) => each['file'] == file);

    // Filled even on a refusal — seeing what was rejected is most of understanding why.
    final content = StringBuffer()
      ..writeln('project:')
      ..writeln('  name: "$name"')
      ..writeln('  security_class: "$klass"')
      ..writeln('image:')
      ..writeln('  base_image: "$baseImage"');
    if (upstream.isNotEmpty) {
      content
        ..writeln('upstream:')
        ..writeln('  url: "$upstream"');
    }
    if (sets.isNotEmpty) {
      content
        ..writeln('egress:')
        ..writeln('  sets: [${sets.join(', ')}]');
    }

    if (!preview && !blocked && !exists) _createdProjects.add(file);

    return <String, dynamic>{
      'outcome': blocked
          ? 'INVALID'
          : exists
              ? 'ALREADY_EXISTS'
              : preview
                  ? 'PREVIEWED'
                  : 'CREATED',
      'file': file,
      'content': content.toString(),
      'problems': problems,
      'detail': exists ? 'a project file is already there' : '',
    };
  }

  static Map<String, dynamic> _problem(String field, String what, {required bool fatal}) =>
      <String, dynamic>{'field': field, 'what': what, 'fatal': fatal};

  /// The egress sets this machine has, by name, for checking answers against.
  static const _knownSets = <String>['dart-packages', 'containers', 'forges'];

  /// Project files this mock has been asked to create, so a second attempt is refused.
  final Set<String> _createdProjects = <String>{};

  /// Takes names back from a running task.
  ///
  /// **It stops new connections and not the ones already running** — the ruleset accepts
  /// established traffic without consulting the set again. Nothing here models that, because
  /// nothing here has traffic; the interface says it, and this is where the wording is checked
  /// against a real reply.
  Map<String, dynamic> _narrowTask(Map<String, dynamic> parameters) {
    final name = parameters['task'] as String? ?? '';
    final asked = (parameters['domains'] as List?)?.cast<String>() ?? <String>[];
    final scope = parameters['scope'] as String? ?? '';
    final preview = parameters['dryRun'] == true;

    if (scope.isEmpty) throw const MockRefusal('org.fuin.sokar.Tasks1.ScopeRequired');

    final task = tasks.firstWhere(
      (each) => each['name'] == name,
      orElse: () => const <String, dynamic>{},
    );
    if (task.isEmpty || task['running'] != true) {
      return _narrowed('NOT_RUNNING', detail: 'there is no running container called $name');
    }

    // Anything not granted to this run is ignored rather than an error.
    final already = _granted[name] ?? const <String>{};
    final closes = <String>[for (final host in asked) if (already.contains(host)) host];
    if (closes.isEmpty) {
      return _narrowed('NO_CHANGE', detail: 'none of those is granted to this run');
    }
    if (preview) {
      return _narrowed('PREVIEWED', closes: closes, addresses: closes.length * 2);
    }

    _granted[name]?.removeAll(closes);

    final file = _fileOf(task['project'] as String? ?? '');
    if (scope == 'RUN_AND_PROJECT' && file.isEmpty) {
      return _narrowed('NO_PROJECT_FILE',
          closes: closes,
          addresses: closes.length * 2,
          detail: 'taken back from the run; no project file is recorded, so nothing was written');
    }
    return _narrowed('NARROWED',
        closes: closes,
        addresses: closes.length * 2,
        persisted: scope == 'RUN_AND_PROJECT');
  }

  static Map<String, dynamic> _narrowed(
    String outcome, {
    List<String> closes = const <String>[],
    int addresses = 0,
    bool persisted = false,
    String detail = '',
  }) =>
      <String, dynamic>{
        'outcome': outcome,
        'closes': closes,
        'addresses': addresses,
        'persisted': persisted,
        'detail': detail,
      };

  /// Turns enforcement on or off on a task that is already running.
  ///
  /// **It opens nothing.** The ruleset stays loaded whichever mode is chosen; what changes is
  /// whether a blocked connection produces a question.
  Map<String, dynamic> _setClearance(Map<String, dynamic> parameters) {
    final name = parameters['task'] as String? ?? '';
    final mode = parameters['mode'] as String? ?? '';
    final preview = parameters['dryRun'] == true;

    if (!const <String>['prompt', 'allow', 'deny', 'off'].contains(mode)) {
      return _clearance('UNKNOWN_MODE', detail: '"$mode" is not a mode this machine knows');
    }
    final at = tasks.indexWhere((each) => each['name'] == name);
    if (at < 0) return _clearance('NO_SUCH_TASK', detail: 'nothing here knows $name');
    if (tasks[at]['running'] != true) {
      return _clearance('NOT_RUNNING', detail: '$name is not up');
    }

    final was = tasks[at]['clearance'] as String? ?? '';
    // Not a failure: it was already in that mode and nothing was restarted.
    if (was == mode) return _clearance('UNCHANGED', was: was);
    if (preview) return _clearance('PREVIEWED', was: was, now: mode);

    tasks[at] = <String, dynamic>{...tasks[at], 'clearance': mode};
    _changes.add(<String, dynamic>{'tasks': tasks});
    return _clearance('CHANGED', was: was, now: mode);
  }

  static Map<String, dynamic> _clearance(
    String outcome, {
    String was = '',
    String now = '',
    String detail = '',
  }) =>
      <String, dynamic>{
        'outcome': outcome,
        'was': was,
        // Empty when nothing changed, exactly as the contract says.
        'now': now,
        'detail': detail,
      };

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
  /// Whether this machine can run a task.
  ///
  /// **One `DEGRADED` and the rest fine**, because a report that is all green proves nothing about
  /// the screen that has to tell three states apart — and degraded is the one that leaves a
  /// machine running while being worth knowing about.
  Map<String, dynamic> _doctor(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        'probes': <Map<String, dynamic>>[
          _probe('podman', 'OK', '5.2.1', ''),
          _probe('hook registration', 'OK', 'registered for this user', ''),
          _probe('rootless network backend', 'DEGRADED',
              'slirp4netns rather than pasta: the git gate binds every interface and is '
                  'reachable from this machine\u0027s network',
              'install pasta (passt) and restart the daemon'),
          _probe('dnsmasq nftset', 'OK', 'built with nftset support', ''),
          _probe('nft', 'OK', 'v1.0.9', ''),
          _probe('git', 'OK', '2.45.2', ''),
          _probe('nsenter', 'OK', 'util-linux 2.40', ''),
          _probe('SELinux policy', 'OK', 'loaded', ''),
          _probe('keyring', 'OK', 'libkeyutils present', ''),
        ],
        // DEGRADED leaves it ready: the machine runs tasks, and the report says how well.
        'ready': true,
      };

  static Map<String, dynamic> _probe(
          String name, String state, String detail, String action) =>
      <String, dynamic>{
        'name': name,
        'state': state,
        'detail': detail,
        'action': action,
      };

  /// Which providers this machine has.
  Map<String, dynamic> _providers(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        'providers': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'a-provider',
            'label': 'A Provider',
            'upstream': 'api.anthropic.com',
            'dialects': <String>['api-key', 'oauth'],
            'authenticated': true,
            'credentialType': 'api-key',
            'credentialName': 'a-provider',
            'storeCommand': 'sokar vault put a-provider',
          },
          // Stored under the *agent's* name, which is the fallback a client could never work out
          // by intersecting two lists.
          <String, dynamic>{
            'name': 'other-provider',
            'label': 'Another Provider',
            'upstream': 'api.other.test',
            'dialects': <String>['oauth'],
            'authenticated': false,
            'credentialType': '',
            'credentialName': 'an-agent',
            'storeCommand': 'sokar vault put an-agent --type oauth',
          },
        ],
        'readable': true,
      };

  /// Imports a credential an agent already holds here.
  Map<String, dynamic> _importCredential(Map<String, dynamic> parameters) {
    final agent = parameters['agent'] as String?;
    // An empty name matches nothing, and omitting it means "the only one installed". Two
    // different things, kept apart here as they are on the daemon.
    if (agent != null && agent != 'an-agent') {
      return <String, dynamic>{
        'outcome': 'NO_SUCH_AGENT',
        'name': '',
        'type': '',
        'length': 0,
        'source': '',
        'detail': 'no agent called \u0027$agent\u0027 is installed here',
      };
    }
    return <String, dynamic>{
      'outcome': 'IMPORTED',
      'name': 'an-agent',
      'type': 'api-key',
      'length': 51,
      'source': '/home/michi/.config/an-agent/credentials.json',
      'detail': '',
    };
  }

  /// What has been backed up, by project. **A record rather than a listing of files**: a bundle
  /// is written wherever an operator names it, so nothing could work this out afterwards.
  final Map<String, List<Map<String, dynamic>>> _backupRecords =
      <String, List<Map<String, dynamic>>>{
    'checkout': <Map<String, dynamic>>[
      <String, dynamic>{
        'taken': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'bundle': '/srv/checkout/backups/before-sync.bundle',
        'refs': 2,
        'present': true,
        'bytes': 4823 * 1024,
      },
      // A bundle somebody moved. Listed, because it was taken — dropping it would say the backup
      // was never made, which is a different and worse statement.
      <String, dynamic>{
        'taken': DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'bundle': '/srv/checkout/backups/last-week.bundle',
        'refs': 5,
        'present': false,
        'bytes': 0,
      },
    ],
  };

  Map<String, dynamic> _backups(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        // Newest first, and empty is ordinary: a project nobody has backed up.
        'backups': _backupRecords[parameters['project']] ?? <Map<String, dynamic>>[],
      };

  Map<String, dynamic> _deleteBackup(Map<String, dynamic> parameters) {
    final project = parameters['project'] as String? ?? '';
    final bundle = parameters['bundle'] as String? ?? '';
    final preview = parameters['dryRun'] == true;
    final records = _backupRecords[project] ?? <Map<String, dynamic>>[];
    final known = records.where((each) => each['bundle'] == bundle);
    if (known.isEmpty) {
      // Refused rather than obeyed: otherwise this is a file-deletion primitive wearing a
      // backup's name, reachable by anything that can open the socket.
      return <String, dynamic>{
        'outcome': 'NO_SUCH_BACKUP',
        'fileRemoved': false,
        'refs': 0,
        'detail': 'no record names that path',
      };
    }
    final record = known.first;
    if (!preview) {
      _backupRecords[project] =
          records.where((each) => each['bundle'] != bundle).toList();
    }
    return <String, dynamic>{
      'outcome': preview ? 'PREVIEWED' : 'DELETED',
      // False with DELETED means the record was cleared for a bundle somebody had already
      // moved — a tidy-up, not a loss.
      'fileRemoved': record['present'] == true,
      'refs': record['refs'],
      'detail': '',
    };
  }

  Map<String, dynamic> _restoreBackup(Map<String, dynamic> parameters) {
    final project = parameters['project'] as String? ?? '';
    final bundle = parameters['bundle'] as String? ?? '';
    final preview = parameters['dryRun'] == true;
    final force = parameters['force'] == true;
    final records = _backupRecords[project] ?? <Map<String, dynamic>>[];
    if (!records.any((each) => each['bundle'] == bundle)) {
      return <String, dynamic>{
        'outcome': 'NO_SUCH_BACKUP',
        'mirror': '',
        'unreviewed': <String>[],
        'detail': 'no record names that path',
      };
    }
    // The checkout gate holds unreviewed work, so restoring over it destroys the only copy
    // there has ever been. That is the refusal worth having.
    final unreviewed = project == 'checkout' ? _waiting.keys.toList() : <String>[];
    final refused = unreviewed.isNotEmpty && !preview && !force;
    return <String, dynamic>{
      'outcome': preview
          ? 'PREVIEWED'
          : refused
              ? 'HOLDS_WORK'
              : 'RESTORED',
      'mirror': '/srv/$project/.sokar/mirror',
      // Filled under force too: it is what force destroyed, and that belongs in the record
      // afterwards rather than only in the warning.
      'unreviewed': unreviewed,
      'detail': '',
    };
  }

  Map<String, dynamic> _syncUpstream(Map<String, dynamic> parameters) {
    final project = parameters['project'] as String? ?? '';
    if (project == 'billing') {
      // Offline: nothing was tried, and zero would read as up to date.
      return <String, dynamic>{
        'outcome': 'MEASURED',
        'behind': 0,
        'measured': false,
        'reason': 'OFFLINE',
        'detail': '',
      };
    }
    if (project == 'never-run') {
      return <String, dynamic>{
        'outcome': 'NO_MIRROR',
        'behind': 0,
        'measured': false,
        'reason': 'NEVER_CHECKED',
        'detail': '',
      };
    }
    return <String, dynamic>{
      'outcome': 'MEASURED',
      'behind': 3,
      'measured': true,
      'reason': 'MEASURED',
      'detail': '',
    };
  }

  /// What this mock answers when asked which node it is.
  final String _nodeId =
      'mock-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';

  /// Projects removed by `DeleteProject`, which stop being listed.
  final Set<String> _removedProjects = <String>{};

  Map<String, dynamic> _projects(Map<String, dynamic> parameters) =>
      <String, dynamic>{
        'projects': <Map<String, dynamic>>[
          for (final project in _everyProject)
            if (!_removedProjects.contains(project['name'])) project,
        ],
      };

  List<Map<String, dynamic>> get _everyProject => <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'checkout',
            'securityClass': 'guarded',
            'file': '/srv/checkout/project.yml',
            'mirror': '/srv/checkout/.sokar/mirror',
            'prepared': true,
            'preparedState': 'READY',
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
            'preparedState': 'STALE',
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
            'preparedState': 'ABSENT',
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
            'preparedState': 'UNKNOWN',
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
      ];

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
  /// Builds a project's image without starting anything.
  ///
  /// **Streamed, because a build takes minutes** and showing nothing for that long is
  /// indistinguishable from having hung. The depth decides how much of it runs — which is the
  /// whole reason three depths exist rather than one button.
  Stream<Map<String, dynamic>> _prepare(Map<String, dynamic> parameters) async* {
    final depth = parameters['rebuild'] as String? ?? 'CACHED';
    final steps = <String>[
      'STEP 1/6: FROM ubuntu:24.04',
      if (depth == 'EVERYTHING') '  --> downloading the base layers again',
      'STEP 2/6: RUN apt-get update',
      if (depth == 'EVERYTHING')
        '  --> installing packages'
      else
        '  --> using cache',
      'STEP 4/6: ARG SOKAR_AGENT_LAYER',
      if (depth == 'CACHED')
        '  --> using cache'
      else
        '  --> the agent layer is invalidated from here down',
      'STEP 5/6: RUN install-agent',
      'STEP 6/6: COPY project snippet',
    ];
    for (final line in steps) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      yield <String, dynamic>{'line': line};
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    yield <String, dynamic>{
      'outcome': 'PREPARED',
      'image': 'sokar/${parameters['project']}:latest',
      // Read back rather than echoed blindly: a depth this daemon did not recognise has to be
      // visible instead of silently defaulted.
      'rebuild': depth,
      'output': <String>[],
      'detail': '',
    };
  }

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
        // Its own ref is waiting at the gate, which is what `waiting` says and what nothing
        // could be joined to work out.
        _task('sokar-checkout-migrate', 'checkout',
            running: false, helpers: 0, waiting: 1),
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
    int waiting = 0,
  }) =>
      <String, dynamic>{
        'name': name,
        'label': '',
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
        // The ref carries the *task* name, which is the container name without the project
        // prefix — not the container name itself, which has the run in it.
        'branch': 'refs/sokar/incoming/${name.replaceFirst('sokar-$project-', '')}',
        'since': DateTime.now()
            .toUtc()
            .subtract(Duration(minutes: minutesAgo))
            .toIso8601String(),
        'activity': running ? activity : 'DEAD',
        'waitingFor': waitingFor,
        'clearance': clearance,
        'waiting': waiting,
      };
}
