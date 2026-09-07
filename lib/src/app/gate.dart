import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'diff.dart';
import 'fleet_backend.dart';

/// What is waiting at one project's gate, and what is being made of it.
///
/// The gate is where work an agent finished sits until a person decides about it. Nothing leaves
/// the machine until somebody does: `Approve` is the only call in the whole contract that sends
/// anything anywhere, and it makes the caller name the branch rather than inferring one.
class Gate extends ChangeNotifier {
  /// Which project's gate this is, or null before one has been looked at.
  Project? project;

  /// Where the mirror is, once asked.
  String mirror = '';

  /// offline, gatekeeping or online.
  String mode = '';

  /// What is waiting, oldest answer first.
  List<PendingPush> waiting = const <PendingPush>[];

  /// Whether something is being asked for right now.
  bool busy = false;

  /// Why the gate could not be read or acted on, in words. Null when nothing is wrong.
  String? problem;

  /// The push being looked at, or null.
  PendingPush? looking;

  /// Its diff, as the gate answered it.
  String diff = '';

  /// Its commit log over the same range.
  String log = '';

  /// The files that diff touches.
  List<ChangedFile> get changed => parseUnifiedDiff(diff);

  /// Whether this project can be asked about at all.
  ///
  /// Every gate method takes the project's file, so a project without one is listed and cannot be
  /// acted on. Saying that beats a dialog that opens on nothing.
  bool get reachable => project?.canBeActedOn ?? false;

  /// Reads what is waiting at [project]'s gate.
  Future<void> lookAt(FleetBackend backend, Project project) async {
    this.project = project;
    looking = null;
    diff = '';
    log = '';
    if (!project.canBeActedOn) {
      waiting = const <PendingPush>[];
      problem = 'No project file is recorded for ${project.name}, and every gate call takes '
          'one. Running a task with it once records it.';
      notifyListeners();
      return;
    }
    await _asking(() async {
      final gate = await backend.gateOf(project.file);
      mirror = gate.mirror;
      mode = gate.mode;
      waiting = gate.pending;
    });
  }

  /// Opens one waiting push, so it can be judged before it is forwarded.
  Future<void> look(FleetBackend backend, PendingPush push, {String? against}) async {
    looking = push;
    diff = '';
    log = '';
    notifyListeners();
    final file = project?.file;
    if (file == null || file.isEmpty) return;
    await _asking(() async {
      final review = await backend.reviewOf(file, push.name, against: against);
      diff = review.diff;
      log = review.log;
    });
  }

  /// Forwards the push being looked at onto [branch].
  Future<String> approve(FleetBackend backend, String branch) async {
    final file = project?.file;
    final push = looking;
    if (file == null || push == null) return '';
    var said = '';
    await _asking(() async {
      await backend.approve(file, push.name, branch);
      said = '${push.subject} was forwarded to $branch.';
      looking = null;
      await _readAgain(backend, file);
    });
    return problem ?? said;
  }

  /// Drops the request. The work stays in the mirror; only the asking is gone.
  Future<String> reject(FleetBackend backend) async {
    final file = project?.file;
    final push = looking;
    if (file == null || push == null) return '';
    var said = '';
    await _asking(() async {
      await backend.reject(file, push.name);
      said = '${push.subject} was dropped. The work is still in the mirror.';
      looking = null;
      await _readAgain(backend, file);
    });
    return problem ?? said;
  }

  Future<void> _readAgain(FleetBackend backend, String file) async {
    final gate = await backend.gateOf(file);
    mirror = gate.mirror;
    mode = gate.mode;
    waiting = gate.pending;
  }

  Future<void> _asking(Future<void> Function() ask) async {
    busy = true;
    problem = null;
    notifyListeners();
    try {
      await ask();
    } on VarlinkException catch (refusal) {
      // A named refusal is an answer: BranchRequired and ProjectRequired both land here, and both
      // are things somebody did rather than things that broke.
      problem = _wordsFor(refusal);
    } on VarlinkDisconnected catch (ex) {
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static String _wordsFor(VarlinkException refusal) => switch (refusal.simpleName) {
        'BranchRequired' => 'A branch has to be named. Nothing is forwarded onto a guess.',
        'ProjectRequired' => 'No project file was given, and every gate call takes one.',
        'Failed' => '${refusal.parameters['message'] ?? 'It did not work.'}',
        _ => 'Refused: ${refusal.simpleName}.',
      };
}
