import 'dart:io';

import 'package:flutter/foundation.dart';

import 'connection_trial.dart';
import 'host_keys.dart';
import 'machine_setup.dart';
import 'machines.dart';

/// The steps of preparing a machine, in order. Adding a user to a machine prepared before walks
/// the same steps; only what the first one asks differs.
enum SetupStep {
  /// The key it is reached with.
  key,

  /// Where it is, and root logging in.
  where,

  /// Sokar's setup script.
  prepare,

  /// Reaching it as the work user.
  reach,

  /// Optionally turning off root and password login, then watching it.
  harden,
}

/// One run of the machine wizard: what was said, what was done, and what is being done now.
///
/// **Held apart from the screen** so going back and forth never loses anything, and **kept in the
/// settings** after every step so a cancelled wizard or a closed window picks up where it stopped.
/// What is kept never includes a private key: only where a kept one lives.
class SetupRun extends ChangeNotifier {
  /// Constructor taking what the first page said and what does the work.
  SetupRun({
    required this.name,
    required this.workUser,
    required this.setup,
    this.addingAUser = false,
    this.hostKeys,
    this.trying,
    this.remember,
  }) : keyFile = addingAUser
            ? (setup.existingKeys().firstOrNull ?? setup.sshKeys().firstOrNull ?? '')
            : '';

  /// Picks a run up again from what [toStored] kept, or null when it is not one.
  static SetupRun? fromStored(
    Map<String, Object?> stored, {
    required MachineSetup setup,
    HostKeys? hostKeys,
    Future<Trial> Function(Machine machine)? trying,
    Future<void> Function(Map<String, Object?>? draft)? remember,
  }) {
    String text(String key) => stored[key] is String ? stored[key] as String : '';
    if (text('name').isEmpty || text('workUser').isEmpty) return null;
    final run = SetupRun(
      name: text('name'),
      workUser: text('workUser'),
      setup: setup,
      addingAUser: stored['addingAUser'] == true,
      hostKeys: hostKeys,
      trying: trying,
      remember: remember,
    );
    run
      ..publicKey = text('publicKey')
      ..host = text('host')
      ..prepared = stored['prepared'] == true;
    final kept = text('kept');
    // A kept key that is no longer there is no key: that step is asked again.
    if (kept.isNotEmpty && File(kept).existsSync()) {
      run
        ..kept = kept
        ..keyFile = kept;
    }
    final chosen = stored['chosen'];
    if (chosen is List) run.chosen.addAll(chosen.whereType<String>());
    final step = SetupStep.values.where((each) => each.name == text('step')).firstOrNull;
    run.step = run.kept == null ? SetupStep.key : (step ?? SetupStep.key);
    // Root has to log in again after a pause; that is cheap, and proves the key still works.
    if (run.step.index > SetupStep.where.index && !run.prepared) run.step = SetupStep.where;
    if (run.step == SetupStep.harden) run.step = SetupStep.reach;
    return run;
  }

  /// What the machine is called, which names its key and its `Host` entry.
  final String name;

  /// The user it runs work as.
  final String workUser;

  /// Whether this only adds a user to a machine prepared before.
  final bool addingAUser;

  /// Makes and checks the key, and runs commands there.
  final MachineSetup setup;

  /// Confirms the host key before the first login, or null where nothing can.
  final HostKeys? hostKeys;

  /// Tries the prepared machine the way watching it will, or null where nothing can.
  final Future<Trial> Function(Machine machine)? trying;

  /// Keeps the run for later, or forgets it with null.
  final Future<void> Function(Map<String, Object?>? draft)? remember;

  SetupStep step = SetupStep.key;

  /// The pasted or generated key, before it is kept.
  String privateKey = '';
  String publicKey = '';

  /// The key file root logs in with, when adding a user.
  String keyFile;

  /// Where the key was kept, once it was.
  String? kept;

  /// The server's name or address, as typed.
  String host = '';

  /// Whether root logged in with the kept key, for the host as it is now typed.
  String? loggedInTo;

  /// What the machine could install; null before it was asked.
  List<InstallablePackage>? offered;

  /// The packages chosen besides what is always installed.
  final Set<String> chosen = <String>{};

  /// What `--show` printed, and for which choice.
  String? shown;
  String? shownFor;

  /// What the running script printed so far, line by line.
  final List<String> output = <String>[];

  /// Whether the setup script prepared the machine.
  bool prepared = false;

  /// What reaching it as the work user did, line by line.
  final List<String> log = <String>[];

  /// The machine as it will be watched, once it answered.
  Machine? ready;

  /// Whether root and password logins were turned off.
  bool hardened = false;

  /// What is being done right now, in words, or null when nothing is.
  String? doing;

  /// What the last action said, and whether it was a refusal.
  String? said;
  bool saidIsBad = false;

  bool get busy => doing != null;

  /// The key's file name under `~/.ssh`.
  String get keyName => 'sokar-${Machine.slug(name)}';

  /// The `Host` entry the machine is reached through.
  String get alias => 'sokar-${Machine.slug(name)}';

  /// The choice as one comparable word.
  String get choice => (chosen.toList()..sort()).join(' ');

  /// Whether the step showing is done, so the wizard may go on.
  bool get canGoOn => switch (step) {
        SetupStep.key => kept != null,
        SetupStep.where => loggedInTo != null && loggedInTo == host.trim(),
        SetupStep.prepare => prepared,
        SetupStep.reach => ready != null,
        SetupStep.harden => false,
      };

  bool get isFirst => step == SetupStep.key;
  bool get isLast => step == SetupStep.harden;

  void next() => _goTo(SetupStep.values[step.index + 1]);
  void previous() => _goTo(SetupStep.values[step.index - 1]);

  void _goTo(SetupStep to) {
    step = to;
    said = null;
    notifyListeners();
    _keep();
  }

  /// Something the person typed or ticked: kept, and drawn again.
  void changed() {
    notifyListeners();
    _keep();
  }

  /// What is kept of this run: never a private key.
  Map<String, Object?> toStored() => <String, Object?>{
        'name': name,
        'workUser': workUser,
        'addingAUser': addingAUser,
        'step': step.name,
        'kept': kept ?? '',
        'publicKey': kept == null ? '' : publicKey,
        'host': host,
        'prepared': prepared,
        'chosen': chosen.toList()..sort(),
      };

  void _keep() => remember?.call(toStored());

  /// Forgets the run: it was finished, or the person discarded it.
  Future<void> forget() async => remember?.call(null);

  Future<void> generate() => _doing('Generating a key pair…', () async {
        final pair = await setup.generate('sokar $name');
        privateKey = pair.privateKey;
        publicKey = pair.publicKey;
        return null;
      });

  Future<void> keep() => _doing('Checking the two halves belong together…', () async {
        final pair = KeyPair(privateKey: privateKey, publicKey: publicKey.trim());
        final wrong = await setup.mismatch(pair);
        if (wrong != null) throw MachineSetupFailed(wrong);
        kept = await setup.save(pair, keyName);
        return 'Kept as $kept.';
      });

  Future<void> useKey() => _doing('Reading the key…', () async {
        final file = keyFile.trim();
        publicKey = await setup.publicKeyOf(file);
        kept = file;
        return 'Root logs in with $file, and $workUser will too.';
      });

  /// Logs in as root, asking [confirm] about a host key seen for the first time.
  Future<void> tryRoot(Future<bool> Function(HostKeyCheck check) confirm) =>
      _doing('Logging in as root…', () async {
        final target = host.trim();
        loggedInTo = null;
        final keys = hostKeys;
        if (keys != null) {
          final check = await keys.check('root@$target');
          if (check.problem != null) throw MachineSetupFailed(check.problem!);
          if (!check.known) {
            if (!await confirm(check)) {
              throw MachineSetupFailed(
                  'The host key of ${check.host} was not trusted, so nothing logged in.');
            }
            await keys.accept(check);
          }
        }
        final failed = await setup.loginAsRoot(target, kept!);
        if (failed != null) throw MachineSetupFailed(failed);
        loggedInTo = target;
        return 'Logged in as root on $target with $kept.';
      });

  Future<void> listPackages() => _doing('Asking the machine what it can install…', () async {
        final listed = await _root(MachineSetup.listInstallable());
        if (listed.exitCode != 0) {
          throw MachineSetupFailed(
              '${MachineSetup.whatTheScriptSaid(listed.exitCode)}\n${both(listed)}'.trim());
        }
        offered = MachineSetup.installableIn('${listed.stdout}');
        chosen.removeWhere((name) => !offered!.any((each) => each.name == name));
        final why = '${listed.stderr}'.trim();
        return offered!.isEmpty && why.isNotEmpty ? why : null;
      });

  Future<void> show() => _doing("Fetching Sokar's setup script and asking what it would do…", () async {
        shown = null;
        final now = choice;
        final result = await _root(MachineSetup.show(workUser, chosen.toList()..sort()));
        final said = both(result);
        if (result.exitCode != 0) {
          throw MachineSetupFailed('${MachineSetup.whatTheScriptSaid(result.exitCode)}\n$said');
        }
        shown = said;
        shownFor = now;
        return null;
      });

  Future<void> prepare() => _doing("Running Sokar's setup script as root…", () async {
        final ran = await _root(MachineSetup.prepare(workUser, chosen.toList()..sort()));
        if (ran.exitCode != 0) throw MachineSetupFailed(MachineSetup.whatTheScriptSaid(ran.exitCode));
        prepared = true;
        return MachineSetup.whatTheScriptSaid(0);
      });

  Future<void> reach() => _doing('Setting it up for $workUser and connecting…', () async {
        log.clear();
        final allowed = await setup.asRoot(
            loggedInTo!, kept!, MachineSetup.authorize(workUser, publicKey.trim()));
        if (allowed.exitCode != 0) {
          throw MachineSetupFailed('The key could not be allowed for $workUser: ${both(allowed)}');
        }
        _logged('The key logs in as $workUser.');
        _logged(await setup.addHostEntry(alias: alias, host: loggedInTo!, user: workUser, keyFile: kept!));
        final started = await setup.asUser(alias, 'systemctl --user enable --now sokard');
        if (started.exitCode != 0) {
          throw MachineSetupFailed('Sokar did not start as $workUser: ${both(started)}');
        }
        _logged('Sokar runs as $workUser.');
        final uid = await setup.asUser(alias, 'id -u');
        final id = '${uid.stdout}'.trim();
        if (uid.exitCode != 0 || int.tryParse(id) == null) {
          throw MachineSetupFailed('Which uid $workUser has could not be asked: ${both(uid)}');
        }
        final doctor = await setup.asUser(alias, 'sokar doctor');
        _logged('sokar doctor${doctor.exitCode == 0 ? '' : ' (ended with ${doctor.exitCode})'}:');
        _logged(both(doctor));
        final machine = Machine(
          name: name,
          socketPath: Machine.endpointFor(name),
          host: alias,
          remoteSocket: '/run/user/$id/sokar/sokard.sock',
        );
        final trying = this.trying;
        if (trying != null) {
          final trial = await trying(machine);
          _logged(trial.words);
          if (!trial.reached) throw MachineSetupFailed('It does not answer yet: ${trial.words}');
        }
        ready = machine;
        return 'Ready to watch.';
      });

  Future<void> harden() => _doing('Turning off root and password login…', () async {
        final done = await _root(MachineSetup.harden);
        if (done.exitCode != 0) throw MachineSetupFailed('Root login is still on: ${both(done)}');
        hardened = true;
        return 'Logging in as root and with a password is off.';
      });

  /// A root script, its lines shown as they arrive.
  Future<ProcessResult> _root(String script) {
    output.clear();
    return setup.asRootLive(loggedInTo!, kept!, script, (line) {
      output.add(line);
      notifyListeners();
    });
  }

  void _logged(String line) {
    log.add(line);
    notifyListeners();
  }

  /// Runs one action, saying what it is doing while it does, and what it did or why it could not.
  Future<void> _doing(String what, Future<String?> Function() action) async {
    doing = what;
    said = null;
    notifyListeners();
    String? result;
    var bad = false;
    try {
      result = await action();
    } on MachineSetupFailed catch (ex) {
      result = ex.message;
      bad = true;
    } on Exception catch (ex) {
      // Anything else still ends with words rather than a step busy for ever. What a file or
      // process error says names paths and programs, never a key's contents.
      result = 'That did not work: $ex';
      bad = true;
    }
    doing = null;
    said = result;
    saidIsBad = bad;
    notifyListeners();
    _keep();
  }

  /// What a program printed on both streams.
  static String both(ProcessResult result) => <String>[
        '${result.stdout}'.trim(),
        '${result.stderr}'.trim(),
      ].where((each) => each.isNotEmpty).join('\n');
}
