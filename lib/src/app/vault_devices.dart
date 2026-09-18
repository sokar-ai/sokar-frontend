import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'device_key.dart';
import 'fleet_backend.dart';

/// The devices that open a machine's vault, and this device among them: Sokar B60's keyslots.
///
/// **Built against B60's proposal**, which is not on `Tasks1` yet; until it is, every call answers
/// [FeatureNotSupported] and this says so rather than showing an empty list.
///
/// **The share never leaves this device except to the node it enrolls with.** It is generated here,
/// kept in [store] — the platform's keystore — and sent in the two calls that need it. Nothing here
/// logs it, shows it or puts it in an operation record.
class VaultDevices extends ChangeNotifier {
  /// Constructor taking where this device keeps its keys.
  VaultDevices(this.store);

  /// Where this device keeps its keys.
  final DeviceKeyStore store;

  /// Every credential that can open the vault, as the machine last said.
  List<Keyslot> slots = const <Keyslot>[];

  /// This device's key for the machine last looked at, or null when it is not enrolled there.
  DeviceKey? mine;

  /// Whether a call is outstanding.
  bool busy = false;

  /// Why the last call could not be made or answered, in words.
  String? problem;

  /// What the last call did, in words.
  String? said;

  /// Stamps each question, so an answer to an older one is never drawn over a newer one.
  int _asked = 0;

  /// Whether this device holds a key for the machine last looked at.
  bool get enrolledHere => mine != null;

  /// Reads the machine's keyslots and this device's key for it.
  Future<void> look(FleetBackend backend) => _ask((mine) async {
        final node = await backend.node();
        final slots = await backend.keyslots();
        final key = node.isEmpty ? null : await store.read(node);
        if (mine != _asked) return;
        this.slots = slots;
        this.mine = key;
      });

  /// Enrolls this device under [name].
  ///
  /// **The key is kept before it is sent**, so a machine that accepted it while the answer was lost
  /// still has a device that holds it; a refusal removes it again. A second try sends the same share,
  /// which the node recognizes as already enrolled rather than making a second keyslot.
  Future<void> enroll(FleetBackend backend, String name) => _ask((mine) async {
        final node = await backend.node();
        if (node.isEmpty) {
          problem = 'This machine does not say which node it is, so a key kept for it could not be '
              'found again. Nothing was enrolled.';
          return;
        }
        final pending = await store.read(node);
        final share = pending?.share ?? newShare();
        await store.write(node, DeviceKey(slot: pending?.slot ?? '', share: share));
        try {
          final answer = await backend.enrollDevice(name: name, share: share, storage: store.storage);
          final slot = answer.slot;
          final kept = (answer.outcome == KeyslotOutcome.enrolled ||
                  answer.outcome == KeyslotOutcome.alreadyEnrolled) &&
              slot != null;
          if (kept) {
            await store.write(node, DeviceKey(slot: slot.id, share: share));
          } else {
            await store.delete(node);
          }
          said = keyslotWords(answer.outcome, name: slot?.name ?? name, detail: answer.detail);
        } on FeatureNotSupported {
          await store.delete(node);
          rethrow;
        }
        await _reread(backend, node);
      });

  /// Opens the vault with this device's key for [minutes], or until it is shut when null.
  Future<void> unlock(FleetBackend backend, {required int? minutes}) => _ask((mine) async {
        final node = await backend.node();
        final key = node.isEmpty ? null : await store.read(node);
        if (key == null) {
          problem = 'This device is not enrolled on this machine, so it has nothing to open the vault '
              'with.';
          return;
        }
        final answer = await backend.unlockWithShare(
          share: key.share,
          slot: key.slot.isEmpty ? null : key.slot,
          minutes: minutes,
        );
        said = keyslotWords(answer.outcome, until: clockTime(answer.until), detail: answer.detail);
      });

  /// Revokes [slot]. **Revoking this device forgets its key here too**, since it opens nothing now.
  Future<void> revoke(FleetBackend backend, Keyslot slot) => _ask((mine) async {
        final node = await backend.node();
        final answer = await backend.revokeKeyslot(slot.id);
        if (answer.outcome == KeyslotOutcome.revoked && node.isNotEmpty) {
          final key = await store.read(node);
          if (key != null && key.slot == slot.id) await store.delete(node);
        }
        said = keyslotWords(answer.outcome, name: slot.name, detail: answer.detail);
        if (mine != _asked) return;
        slots = answer.remaining;
        this.mine = node.isEmpty ? null : await store.read(node);
      });

  Future<void> _reread(FleetBackend backend, String node) async {
    slots = await backend.keyslots();
    mine = await store.read(node);
  }

  Future<void> _ask(Future<void> Function(int mine) doing) async {
    final mine = ++_asked;
    busy = true;
    problem = null;
    said = null;
    notifyListeners();
    try {
      await doing(mine);
    } on VarlinkDisconnected catch (ex) {
      if (mine == _asked) problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported {
      if (mine == _asked) {
        problem = "This machine's Sokar cannot enroll devices yet: that arrives with Sokar B60.";
      }
    } finally {
      if (mine == _asked) {
        busy = false;
        notifyListeners();
      }
    }
  }
}

/// An instant from the machine as a time of day here, or as it came when it is not one.
String clockTime(String instant) {
  final parsed = DateTime.tryParse(instant)?.toLocal();
  if (parsed == null) return instant;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(parsed.hour)}:${two(parsed.minute)}';
}

/// What a keyslot call did, as a sentence, for every outcome B60 proposes and any it adds later.
String keyslotWords(KeyslotOutcome outcome, {String name = '', String until = '', String detail = ''}) =>
    switch (outcome.name) {
      'ENROLLED' => 'This device can open the vault now, as "$name".',
      'ALREADY_ENROLLED' => 'This device was enrolled already, as "$name".',
      'UNKNOWN_STORAGE' =>
        'The machine does not know how this device keeps its key, so it enrolled nothing.',
      'BAD_SHARE' => 'The machine refused the key this device made. Nothing was enrolled.',
      'VAULT_LOCKED' =>
        'The vault is locked. A device is enrolled into an open vault, so unlock it at the machine '
            'first.',
      'VAULT_WITHOUT_KEYSLOTS' => "This machine's vault predates devices, so nothing was enrolled.",
      'REVOKED' => '"$name" can no longer open the vault.',
      'NO_SUCH_SLOT' => '"$name" was already gone.',
      'LAST_WAY_IN' => '"$name" is the last way into the vault, so the machine kept it.',
      'UNLOCKED' => until.isEmpty ? 'The vault is open.' : 'The vault is open until $until.',
      'SHARE_REJECTED' => "The machine did not accept this device's key: it was revoked, or never "
          'enrolled on this machine.',
      'ALREADY_OPEN' => 'The vault was open already.',
      _ => detail.isEmpty ? 'That did not work, and the machine did not say why.' : detail,
    };

/// What a device's way of keeping its key protects against, **never said stronger than it is**.
String storageWords(KeyslotStorage storage) => switch (storage.name) {
      'USER_SCOPED' => 'Kept in a keyring that opens at login: anything running as this user can read it.',
      'APPLICATION_SCOPED' => 'Kept where only this application can read it.',
      'FIDO2' => 'Released only with a touch on a security key.',
      'TPM2' => "Released only with a PIN, by this machine's TPM.",
      _ => 'Kept in a way this build cannot describe, so nothing is claimed for it.',
    };
