import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../app/session.dart';
import 'panes.dart';
import 'tokens.dart';
import 'terminal_links.dart';

/// A shell inside running work, drawn in the window.
///
/// **The window is not the session.** What is at the far end is a multiplexer inside the
/// container, so closing this leaves it running and opening it again finds it as it was. Two of
/// the sentences on this screen exist only to say that, because an interface that people think
/// ends their work when they leave it is one they do not leave.
class SessionView extends StatelessWidget {
  /// Constructor taking the session and the way out.
  const SessionView({
    required this.session,
    required this.focusNode,
    required this.onLeave,
    super.key,
  });

  /// The session being typed into.
  final Session session;

  /// The frame's keyboard for what is open — **handed to the terminal itself**.
  ///
  /// Every other thing that opens over the frame is read rather than typed into, so the frame
  /// holding the keyboard costs them nothing. A terminal is the opposite: with the frame holding
  /// it, `Escape` closed this pane and never reached the far end, which would have made `vim`
  /// unusable inside a session and was found by asking where the key went rather than by
  /// assuming.
  final FocusNode focusNode;

  /// Ends this way in. The work at the far end carries on.
  ///
  /// **The only way out on this screen**: going to another place in the rail leaves the session
  /// open and out of sight, and coming back finds it.
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;

          return Column(
            children: <Widget>[
              PaneHeader(
                title: '${session.task} · ${session.machine.name}',
                trailing: TextButton.icon(
                  key: const Key('leave-session'),
                  onPressed: onLeave,
                  icon: const Icon(Icons.logout, size: Sizes.rowIcon),
                  label: const Text('Leave'),
                ),
              ),
              if (session.problem != null)
                Container(
                  width: double.infinity,
                  color: scheme.errorContainer,
                  padding: const EdgeInsets.all(Space.normal),
                  child: Text(session.problem!, key: const Key('session-problem')),
                )
              else if (session.state == SessionState.over)
                Container(
                  width: double.infinity,
                  color: scheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(Space.normal),
                  child: const Text(
                    'This way in is closed. The work is where you left it.',
                    key: Key('session-over'),
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: scheme.surfaceContainerLowest,
                  child: TerminalView(
                    session.terminal,
                    key: const Key('terminal'),
                    focusNode: focusNode,
                    autofocus: true,
                    padding: const EdgeInsets.all(Space.small),
                    // Read-only once it is over, so keys typed at a dead session do not look
                    // like they went somewhere.
                    readOnly: !session.live,
                    textStyle: const TerminalStyle(fontSize: 13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.normal),
                child: TerminalLinks(session: session),
              ),
              // Said under the terminal rather than in a tooltip, because it is the one fact
              // that decides whether somebody dares to close the window at all.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.normal, vertical: Space.tight),
                child: Text(
                  // Two facts, and the second is the one B16 asks for by name: coming back has to
                  // say what it can show. A figure is the honest form of that — a screen saying
                  // *as much as we have* leaves somebody to guess whether the quiet hour is
                  // missing or simply was quiet.
                  'Closing this window leaves the session running; it ends when the work does. '
                  'Coming back shows the last ${Session.scrollback} lines and no more.',
                  key: const Key('leaving-is-safe'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      );
}

/// Which sessions are open, and which one this is.
