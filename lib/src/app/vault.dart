import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// The protected store: what it holds, by name, and the shutting of it.
///
/// **Never a value.** `Credentials` answers names, kinds and lengths and nothing else, and that is
/// the whole promise of the method — on a socket that can be forwarded over ssh. Nothing here
/// asks for more, and nothing here is put where an operation record or a log could keep it.
///
/// Half of what this requirement asks for happens **at the machine** rather than here, and that is
/// a decision rather than a gap: a daemon has no terminal to take a passphrase at, so it can shut
/// the store and can never open it. The screen says where, which is a different sentence from
/// *this cannot be done*.
class Vault extends ChangeNotifier {
  /// What the store says about itself, or null before it has been asked.
  VaultState? state;

  /// What the last lock did, or null.
  Locked? shut;

  /// Whether it is being asked right now.
  bool busy = false;

  /// Why it could not be read or shut, in words.
  String? problem;

  /// Which question is outstanding.
  ///
  /// **Two parts of the interface asking at once must never leave a stale answer over a newer
  /// one.** Answers can arrive in any order, so each is stamped with the question it belongs to
  /// and an older one is dropped rather than drawn.
  int _asked = 0;

  /// Whether the list of names can be believed.
  ///
  /// A locked store and an empty one both answer with no names, and an interface must not show
  /// them the same way. Corrected on the Sokar side on 2026-09-07: an unlocked, empty store now
  /// answers `readable: true`.
  bool get readable => state?.readable ?? false;

  /// What the store holds, by name.
  List<Credential> get credentials => state?.credentials ?? const <Credential>[];

  /// Reads what the store says about itself.
  Future<void> look(FleetBackend backend) async {
    final mine = ++_asked;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final answer = await backend.credentials();
      if (mine != _asked) return;
      state = answer;
    } on VarlinkDisconnected catch (ex) {
      if (mine != _asked) return;
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      if (mine != _asked) return;
      problem = '$ex';
    } finally {
      if (mine == _asked) {
        busy = false;
        notifyListeners();
      }
    }
  }

  /// Shuts the store, and reads it again so what is on screen is what is true.
  Future<void> lock(FleetBackend backend) async {
    final mine = ++_asked;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final answer = await backend.lock();
      if (mine != _asked) return;
      shut = answer;
      state = await backend.credentials();
    } on VarlinkDisconnected catch (ex) {
      if (mine != _asked) return;
      problem = 'Lost contact with the machine: ${ex.message}. The store may or may not be shut.';
    } on FeatureNotSupported catch (ex) {
      if (mine != _asked) return;
      problem = '$ex';
    } finally {
      if (mine == _asked) {
        busy = false;
        notifyListeners();
      }
    }
  }

  /// Puts the result of a lock away.
  void letItBe() {
    shut = null;
    notifyListeners();
  }
}
