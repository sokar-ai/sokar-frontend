import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// What has been backed up of a project's mirror, and the removing of one.
///
/// **The listing exists because nothing recorded that a backup had been taken.** A bundle is
/// written wherever an operator names it and the command forgets it the moment it returns, so
/// *"what has been taken"* was never a missing listing — it was a question the machine had no data
/// to answer. That bounds what this screen may promise: **backups taken by hand, or before the
/// record existed, are invisible and always will be.** An empty list means *nothing recorded*,
/// never *nothing exists*.
class Backups extends ChangeNotifier {
  /// Which project these belong to.
  String project = '';

  /// What has been taken, newest first.
  List<Backup> taken = const <Backup>[];

  /// What removing one would take, once it has been asked and before it is agreed to.
  BackupDeleted? considering;

  /// Which bundle is being considered.
  String? bundle;

  /// What the last deletion did.
  BackupDeleted? removed;

  /// Whether the machine is being asked right now.
  bool busy = false;

  /// Why it could not be read, in words.
  String? problem;

  /// Whether anything has been read yet.
  bool get asked => problem != null || taken.isNotEmpty || _read;
  bool _read = false;

  /// Reads what has been taken.
  Future<void> look(FleetBackend backend, String name) async {
    project = name;
    busy = true;
    problem = null;
    considering = null;
    removed = null;
    notifyListeners();
    try {
      taken = await backend.backups(name);
      _read = true;
    } on VarlinkDisconnected catch (ex) {
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Asks what removing one would take, removing nothing.
  Future<void> consider(FleetBackend backend, Backup backup) async {
    bundle = backup.bundle;
    removed = null;
    await _asking(() async {
      considering = await backend.deleteBackup(project, backup.bundle, dryRun: true);
    });
  }

  /// Removes the one being considered.
  Future<void> remove(FleetBackend backend) async {
    final path = bundle;
    if (path == null) return;
    await _asking(() async {
      removed = await backend.deleteBackup(project, path);
      considering = null;
      if (removed?.gone ?? false) taken = await backend.backups(project);
    });
  }

  /// Puts what is on screen away.
  void letItBe() {
    bundle = null;
    considering = null;
    removed = null;
    notifyListeners();
  }

  /// What to say about the last deletion, in one line.
  ///
  /// **A record cleared for a bundle somebody had already moved is a tidy-up, not a loss**, and
  /// saying both the same way would tell somebody they had destroyed something they had not.
  String get words {
    final said = removed;
    if (said == null) return '';
    return switch (said.outcome) {
      'DELETED' when said.fileRemoved =>
        'Gone: the bundle and the record of it. It held ${said.refs} '
            '${said.refs == 1 ? 'push' : 'pushes'}.',
      'DELETED' => 'The record is cleared. The file was already gone — somebody had moved it, and '
          'nothing here removed anything.',
      'NO_SUCH_BACKUP' =>
        'No record names that file, so nothing here will remove it. ${said.detail}'.trim(),
      'FAILED' => 'It could not be removed. ${said.detail}'.trim(),
      _ => '${said.outcome}. ${said.detail}'.trim(),
    };
  }

  Future<void> _asking(Future<void> Function() ask) async {
    busy = true;
    problem = null;
    notifyListeners();
    try {
      await ask();
    } on VarlinkDisconnected catch (ex) {
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
