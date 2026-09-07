import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/mock/machine.dart';
import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// Holds the stand-in to the behaviour the interface is built on, over a real socket.
///
/// The frame's own tests run against a hand-written fake, because a widget test's clock cannot
/// carry real input and output. That leaves the thing a person actually opens the interface
/// against — `tool/mock_daemon.dart`, which is this machine — covered by nothing, and it is where
/// the mistake landed: `Stop` answered *removed* and went on listing the task, so a working
/// interface looked like one where nothing happens. Green tests, broken by hand in a minute.
void main() {
  late MockDaemon daemon;
  late MockMachine machine;

  Future<SokarClient> connect() => SokarClient.connect(
      Backend(socketPath: daemon.socketPath, label: 'mock'));

  Future<void> machineIn(String situation) async {
    daemon = MockDaemon();
    await daemon.start();
    machine = MockMachine(daemon, situation: situation, pace: Duration.zero);
    addTearDown(() async {
      await machine.close();
      await daemon.stop();
    });
  }

  test('a task that is stopped stops being listed', () async {
    await machineIn('work');
    final client = await connect();
    expect(await client.tasks(), hasLength(5));

    final stopped = await client.stop('sokar-checkout-migrate');

    expect(stopped.outcome, Outcome.stopped);
    expect(stopped.removed, isTrue);
    expect(
      (await client.tasks()).map((task) => task.name),
      isNot(contains('sokar-checkout-migrate')),
    );
  });

  test('a refused stop changes nothing at all', () async {
    await machineIn('holds-work');
    final client = await connect();

    final refused = await client.stop('sokar-checkout-shell');

    expect(refused.outcome, Outcome.holdsWork);
    expect(refused.removed, isFalse);
    expect(refused.work, isNotEmpty);
    expect(
      (await client.tasks()).map((task) => task.name),
      contains('sokar-checkout-shell'),
    );
  });

  test('asking again with purge gets through, because that is the point of asking', () async {
    await machineIn('holds-work');
    final client = await connect();
    await client.stop('sokar-checkout-shell');

    final purged = await client.stop('sokar-checkout-shell', purge: true);

    expect(purged.removed, isTrue);
    expect(
      (await client.tasks()).map((task) => task.name),
      isNot(contains('sokar-checkout-shell')),
    );
  });

  test('a resumed task is listed as running', () async {
    await machineIn('work');
    final client = await connect();

    final resumed = await client.resume('sokar-checkout-migrate');

    expect(resumed.outcome, Outcome.resumed);
    final task = (await client.tasks())
        .firstWhere((task) => task.name == 'sokar-checkout-migrate');
    expect(task.running, isTrue);
  });

  test('a change reaches a watcher without it asking again', () async {
    await machineIn('work');
    final client = await connect();
    // Driven by the events themselves rather than by a delay: a stream test that waited for wall
    // time is a flaky test, and flaky tests get deleted.
    final seen = <int>[];
    final first = Completer<void>();
    final second = Completer<void>();
    final watching = client.watchTasks().listen((tasks) {
      seen.add(tasks.length);
      if (seen.length == 1) first.complete();
      if (seen.length == 2) second.complete();
    });

    await first.future;
    await client.stop('sokar-checkout-migrate');
    await second.future;

    expect(seen.first, 5);
    expect(seen.last, 4);
    await watching.cancel();
  });

  test('a log is followed, and a name it does not have is refused', () async {
    await machineIn('work');
    final client = await connect();

    final read = await client.tailLog('sokar-checkout-shell', 'agent.log').take(2).toList();
    expect(read.expand((lines) => lines), isNotEmpty);

    await expectLater(
      client.tailLog('sokar-checkout-shell', 'nowhere.log').first,
      throwsA(isA<VarlinkException>()
          .having((refusal) => refusal.simpleName, 'simpleName', 'NoSuchLog')),
    );
  });

  test('a blocked connection arrives, and its answer comes back on the same stream', () async {
    await machineIn('work');
    final client = await connect();

    final seen = <Prompt>[];
    final asked = Completer<void>();
    final answered = Completer<void>();
    final watching = client.prompts().listen((prompt) {
      seen.add(prompt);
      if (seen.length == 1) asked.complete();
      if (seen.length == 2) answered.complete();
    });

    machine.blocks('api.example.test:443');
    await asked.future;
    expect(seen.single.settled, isFalse);
    expect(seen.single.prefix, isNotEmpty);

    await client.decide(seen.first, allow: true);
    await answered.future;

    // The same question a second time, carrying its answer — matched by task and key, because
    // `at` means the decision time here and `prefix` is empty.
    expect(seen.last.identity, seen.first.identity);
    expect(seen.last.settled, isTrue);
    expect(seen.last.verdict, 'allow');
    expect(seen.last.prefix, isEmpty);
    await watching.cancel();
  });

  test('a question that runs out says so, because nothing asks again', () async {
    await machineIn('work');
    final client = await connect();
    final seen = <Prompt>[];
    final expired = Completer<void>();
    final watching = client.prompts().listen((prompt) {
      seen.add(prompt);
      if (prompt.expired) expired.complete();
    });

    machine.expires(machine.blocks('api.example.test:443'));
    await expired.future;

    expect(seen.last.expired, isTrue);
    await watching.cancel();
  });

  test('a task says what it is doing, beside what the runtime says', () async {
    await machineIn('work');
    final client = await connect();

    final tasks = await client.tasks();
    final waiting =
        tasks.firstWhere((task) => task.activity == Activity.waiting);

    expect(waiting.waitingFor, isNotEmpty);
    expect(waiting.state, isNotEmpty, reason: 'state stays the runtime own words');
    expect(waiting.startedAt, isNotNull);
    expect(waiting.mode.recognised, isTrue);
    // A terminal attached means nothing on this side can see it, and that is its own answer.
    expect(tasks.map((task) => task.activity), contains(Activity.unknown));
  });

  test('an activity from a later release renders rather than throwing', () async {
    await machineIn('work');
    daemon.method('List', (_) => <String, dynamic>{
          'tasks': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'a-task', 'activity': 'QUIESCED'},
          ],
        });
    final client = await connect();

    final task = (await client.tasks()).single;

    expect(task.activity.recognised, isFalse);
    expect(task.activity.label, 'quiesced');
  });

  test('a preview writes nothing, and the same change written does', () async {
    await machineIn('work');
    final client = await connect();
    const project = '/srv/checkout/project.yml';

    final (before, _) = await client.egress(project);
    final previewed = await client.setEgress(project,
        addSets: <String>['containers'], dryRun: true);

    expect(previewed.outcome, EgressOutcome.previewed);
    expect(previewed.opens, isNotEmpty);
    // Hosts, not set names: adding one set opens three here.
    expect(previewed.opens.map((host) => host.host), contains('quay.io'));
    final (stillBefore, _) = await client.egress(project);
    expect(stillBefore.length, before.length, reason: 'a preview wrote something');

    final done = await client.setEgress(project, addSets: <String>['containers']);
    expect(done.outcome, EgressOutcome.changed);
    final (after, _) = await client.egress(project);
    expect(after.length, greaterThan(before.length));
  });

  test('a set that is not installed is refused with its name, not an exception', () async {
    await machineIn('work');
    final client = await connect();

    final refused = await client.setEgress('/srv/checkout/project.yml',
        addSets: <String>['nothing-like-this']);

    expect(refused.outcome, EgressOutcome.noSuchSet);
    expect(refused.detail, contains('nothing-like-this'));
  });

  test('what is refused is answered beside what is reachable', () async {
    await machineIn('work');
    final client = await connect();

    final (hosts, refused) = await client.egress('/srv/checkout/project.yml');

    expect(hosts.first.origin, startsWith('agent '));
    expect(refused, isNotEmpty);
  });

  test('a project that has never run anything is still listed', () async {
    // The whole reason to ask rather than derive: a client that built the list from the tasks
    // could never show one, and that is the project most likely to need attention.
    await machineIn('work');
    final client = await connect();

    final projects = await client.projects();

    expect(projects.map((project) => project.name), contains('never-run'));
    expect(
      projects.firstWhere((project) => project.name == 'never-run').tasks,
      0,
    );
  });

  test('a project with no file recorded is listed and cannot be acted on', () async {
    // A state to render, not an error. Every method that acts on a project takes its file.
    await machineIn('work');
    final client = await connect();

    final moved = (await client.projects())
        .firstWhere((project) => project.name == 'moved-away');

    expect(moved.file, isEmpty);
    expect(moved.canBeActedOn, isFalse);
    expect(moved.pending, 1);
  });

  test('what is waiting at the gate can be read, judged and forwarded', () async {
    await machineIn('work');
    final client = await connect();
    const project = '/srv/checkout/project.yml';

    final gate = await client.gate(project);
    expect(gate.mode, 'gatekeeping');
    expect(gate.pending, hasLength(2));

    final (diff, log) = await client.review(project, gate.pending.first.name);
    expect(diff, contains('diff --git'));
    expect(log, contains('commit'));

    await client.approve(project, gate.pending.first.name, 'fix-rounding');

    // Forwarding takes it out of the gate: it has been decided about and is not waiting any more.
    expect((await client.gate(project)).pending, hasLength(1));
  });

  test('forwarding with no branch is refused rather than guessed at', () async {
    // Approve is the only call in the contract that sends anything anywhere. A branch inferred
    // here would be a push nobody decided about.
    await machineIn('work');
    final client = await connect();

    await expectLater(
      client.approve('/srv/checkout/project.yml',
          'refs/sokar/incoming/fix-rounding', ''),
      throwsA(isA<VarlinkException>()
          .having((refusal) => refusal.simpleName, 'simpleName', 'BranchRequired')),
    );
  });

  test('dropping a request takes it out of the gate and sends nothing', () async {
    await machineIn('work');
    final client = await connect();
    const project = '/srv/checkout/project.yml';

    await client.reject(project, 'refs/sokar/incoming/drop-dead-code');

    expect((await client.gate(project)).pending, hasLength(1));
  });

  test('which logs a task has is asked, and an empty answer is normal', () async {
    await machineIn('work');
    final client = await connect();

    final found = await client.logsOf('sokar-checkout-shell');

    expect(found.map((log) => log.name), containsAll(<String>['agent.log', 'gate.log']));
    expect(found.first.bytes, greaterThan(0));
    // The name goes to Tail unchanged; it is a file name and never a path.
    expect(await client.tailLog('sokar-checkout-shell', found.first.name).first,
        isNotEmpty);
  });

  test('a launch streams its lines and then its result', () async {
    await machineIn('failing-start');
    final client = await connect();

    final progress = await client.start(dryRun: true).toList();

    expect(progress.where((step) => step.line != null), isNotEmpty);
    expect(progress.last.isResult, isTrue);
    expect(progress.last.exitCode, 1);
  });
}
