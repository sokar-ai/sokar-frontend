import 'package:flutter/material.dart';

import '../app/host_keys.dart';
import 'tokens.dart';

/// Shows a host's keys the first time it is reached and asks whether to trust them.
///
/// **Trusting is the choice that has to be made, never the one that happens**: the refusal is the
/// plain button and the trust is a separate, deliberate one, because a key accepted without looking
/// is the whole of what somebody in the middle needs.
Future<bool> confirmHostKey(BuildContext context, HostKeyCheck check) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trust ${check.host}?'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'This machine has not been reached from here before. Compare its keys with what '
                'the machine itself says — on a rented server, its console: '
                '`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`.',
              ),
              const SizedBox(height: Space.normal),
              SelectableText(
                check.fingerprints.join('\n'),
                key: const Key('host-key-fingerprints'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('host-key-refuse'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Do not trust it'),
          ),
          FilledButton(
            key: const Key('host-key-accept'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Trust these keys'),
          ),
        ],
      ),
    ) ??
    false;
