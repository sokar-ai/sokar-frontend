import 'dart:async';

import 'package:flutter/material.dart';

import '../app/links.dart';
import '../app/session.dart';
import 'tokens.dart';

/// The web addresses a terminal's program marked as links, each to be opened here with a press —
/// **never on its own**: whoever writes to a terminal would otherwise choose where the browser goes.
class TerminalLinks extends StatelessWidget {
  /// Constructor taking the session whose links these are.
  const TerminalLinks({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: session,
        builder: (context, _) => session.links.isEmpty && session.forwarded == null && session.forwardProblem == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: Space.small),
                child: Wrap(
                  spacing: Space.small,
                  runSpacing: Space.tight,
                  children: <Widget>[
                    if (session.forwarded case final port?)
                      Text(
                        'The login’s reply is forwarded from port $port here to ${session.machine.name}, '
                        'while this terminal is open.',
                        key: const Key('login-reply-forwarded'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (session.forwardProblem case final problem?)
                      Text(problem,
                          key: const Key('login-reply-refused'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    for (final address in session.links)
                      Tooltip(
                        message: '$address',
                        child: OutlinedButton.icon(
                          key: ValueKey<String>('terminal-link $address'),
                          onPressed: () => unawaited(openLink(address)),
                          icon: const Icon(Icons.open_in_new, size: Sizes.rowIcon),
                          label: Text('Open ${address.host}${address.path} in your browser',
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                  ],
                ),
              ),
      );
}
