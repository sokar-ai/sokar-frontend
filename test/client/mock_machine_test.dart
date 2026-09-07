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

  test('a launch streams its lines and then its result', () async {
    await machineIn('failing-start');
    final client = await connect();

    final progress = await client.start(dryRun: true).toList();

    expect(progress.where((step) => step.line != null), isNotEmpty);
    expect(progress.last.isResult, isTrue);
    expect(progress.last.exitCode, 1);
  });
}
