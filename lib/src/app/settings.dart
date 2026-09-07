import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'machines.dart';

/// Where the interface's own preferences live.
///
/// Deliberately a file this application writes itself rather than a preferences plugin: the
/// only thing being stored is which theme somebody picked, and a plugin would add platform
/// code, a registrant entry and a mock to every widget test that touches the shell.
abstract class SettingsStore {
  /// Reads what was stored, or an empty map when nothing has been.
  Future<Map<String, Object?>> read();

  /// Replaces what is stored.
  Future<void> write(Map<String, Object?> values);
}

/// The store used by the application: one JSON file under the user's config directory.
class FileSettingsStore implements SettingsStore {
  /// Constructor, optionally pointed at another file for tests.
  FileSettingsStore({File? file}) : _file = file ?? _defaultFile();

  final File _file;

  static File _defaultFile() {
    final home = Platform.environment['HOME'] ?? '.';
    final config = Platform.environment['XDG_CONFIG_HOME'] ?? '$home/.config';
    return File('$config/sokar/frontend.json');
  }

  @override
  Future<Map<String, Object?>> read() async {
    // A missing or unreadable file is somebody's first run, not a failure worth reporting:
    // the interface has to open either way.
    try {
      if (!await _file.exists()) return const {};
      final decoded = jsonDecode(await _file.readAsString());
      return decoded is Map<String, Object?> ? decoded : const {};
    } on Exception {
      return const {};
    }
  }

  @override
  Future<void> write(Map<String, Object?> values) async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode(values));
    } on Exception {
      // Losing a theme choice is not worth interrupting anybody over.
    }
  }
}

/// A store that keeps values in memory, for tests that restart the interface.
class MemorySettingsStore implements SettingsStore {
  /// Constructor, optionally starting from values as if written by an earlier run.
  MemorySettingsStore([Map<String, Object?> initial = const {}])
      : _values = Map<String, Object?>.of(initial);

  Map<String, Object?> _values;

  @override
  Future<Map<String, Object?>> read() async => Map<String, Object?>.of(_values);

  @override
  Future<void> write(Map<String, Object?> values) async =>
      _values = Map<String, Object?>.of(values);
}

/// What the person chose about how the interface looks.
class Settings extends ChangeNotifier {
  /// Constructor taking where the choices are kept.
  Settings(this._store);

  final SettingsStore _store;

  ThemeMode _appearance = ThemeMode.system;

  /// Light, dark, or whatever the desktop says.
  ThemeMode get appearance => _appearance;

  /// Reads what an earlier run stored. Safe to call before the first frame.
  Future<void> load() async {
    final stored = await _store.read();
    _appearance = _appearanceNamed(stored['appearance']);
    final machines = stored['machines'];
    if (machines is List) {
      _machines = <Map<String, Object?>>[
        for (final each in machines)
          if (each is Map<String, Object?>) each,
      ];
    }
    notifyListeners();
  }

  /// Chooses an appearance and remembers it for the next run.
  Future<void> setAppearance(ThemeMode appearance) async {
    if (appearance == _appearance) return;
    _appearance = appearance;
    notifyListeners();
    await _write();
  }

  /// The machines an earlier run was watching.
  Future<List<Machine>> machines() async {
    final stored = (await _store.read())['machines'];
    if (stored is! List) return const <Machine>[];
    return <Machine>[
      for (final each in stored)
        if (each is Map<String, Object?>) Machine.fromStored(each),
    ];
  }

  /// Remembers which machines to open next time.
  Future<void> rememberMachines(List<Machine> machines) async {
    _machines = <Map<String, Object?>>[
      for (final machine in machines) machine.stored,
    ];
    await _write();
  }

  List<Map<String, Object?>> _machines = const <Map<String, Object?>>[];

  Future<void> _write() => _store.write(<String, Object?>{
        'appearance': _appearance.name,
        'machines': _machines,
      });

  static ThemeMode _appearanceNamed(Object? name) => ThemeMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ThemeMode.system,
      );
}
