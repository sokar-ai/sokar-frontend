import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sokar_frontend/client.dart';

import '../app/diff.dart';
import '../app/gate.dart';
import 'panes.dart';
import 'selection_list.dart';
import 'tokens.dart';

/// What is waiting at a project's gate.
///
/// Work an agent finished and pushed, which has not left the machine and will not until somebody
/// decides. This is the one screen in the product where the decision is taken.
class GateView extends StatelessWidget {
  /// Constructor taking the gate, the keyboard and what a row opens.
  const GateView({
    required this.gate,
    required this.focusNode,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  /// What is waiting, and what is being made of it.
  final Gate gate;

  /// This view's keyboard focus.
  final FocusNode focusNode;

  /// Opens one waiting push.
  final void Function(PendingPush push) onOpen;

  /// Closes the view.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          PaneHeader(
            title: 'Waiting at the gate · ${gate.project?.name ?? ''}',
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close (Esc)',
              onPressed: onClose,
            ),
          ),
          if (gate.problem != null) GateProblem(words: gate.problem!),
          if (gate.mode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.normal,
                vertical: Space.small,
              ),
              child: Row(
                children: <Widget>[
                  Text('Gate is ${gate.mode}',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          Expanded(
            child: SelectionList<PendingPush>(
              items: gate.waiting,
              idOf: (push) => push.id,
              selected: gate.looking?.id,
              onSelect: (id) => onOpen(
                  gate.waiting.firstWhere((push) => push.id == id)),
              onActivate: (id) => onOpen(
                  gate.waiting.firstWhere((push) => push.id == id)),
              focusNode: focusNode,
              emptyMessage: gate.problem != null
                  ? 'Nothing could be read.'
                  : 'Nothing is waiting. Everything this project pushed has been decided.',
              rowOf: (context, push, selected) => _WaitingRow(
                push: push,
                // Named where there is more than one to tell apart: each repository has a gate of
                // its own, and a push is forwarded from the one it waits in.
                repository: gate.repositories.length > 1 ? push.repository : null,
              ),
            ),
          ),
          // **What the gate does not see, said where somebody would otherwise assume it is a
          // wall.** Agent work can still be pushed straight upstream by hand, past this screen
          // entirely. Sokar's guard against that is a pre-push hook, and it is installed **per
          // clone, on the machine somebody pushes from** — which is very often not the machine
          // this interface is talking to, and over a forwarded socket is not reachable from here
          // at all. So this says where it happens rather than offering a control that would only
          // ever protect one machine.
          Padding(
            padding: const EdgeInsets.all(Space.normal),
            child: Text(
              'This is what reached the gate. Work can also be pushed straight upstream by hand, '
              'past it — `sokar gate protect` installs a guard against that, per clone, on the '
              'machine you push from.',
              key: const Key('what-the-gate-does-not-see'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.push, this.repository});

  final PendingPush push;

  final String? repository;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          const Icon(Icons.outbox_outlined, size: Sizes.rowIcon),
          const SizedBox(width: Space.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(push.subject, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  <String>[
                    if (repository != null) 'in $repository',
                    push.commit,
                    'waiting ${push.waiting}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: Sizes.rowIcon),
        ],
      );
}

/// One waiting push, file by file, and the decision about it.
class ReviewView extends StatelessWidget {
  /// Constructor taking the gate and the ways out of it.
  const ReviewView({
    required this.gate,
    required this.onBack,
    required this.onClose,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  /// What is being looked at.
  final Gate gate;

  /// Back to what is waiting.
  final VoidCallback onBack;

  /// Closes the view.
  final VoidCallback onClose;

  /// Forwards it, after asking which branch.
  final VoidCallback onApprove;

  /// Drops the request.
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final push = gate.looking;
    if (push == null) return const SizedBox.shrink();
    final files = gate.changed;

    return Column(
      children: <Widget>[
        PaneHeader(
          title: push.subject,
          leading: BackButton(onPressed: onBack),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            onPressed: onClose,
          ),
        ),
        if (gate.problem != null) GateProblem(words: gate.problem!),
        Expanded(
          child: gate.busy && files.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: Space.small),
                  children: <Widget>[
                    for (final file in files) _File(file: file),
                    if (files.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(Space.loose),
                        child: Text('This push changes no files.'),
                      ),
                  ],
                ),
        ),
        _Decision(
          gate: gate,
          onApprove: onApprove,
          onReject: onReject,
        ),
      ],
    );
  }
}

/// One changed file and its hunks.
///
/// Collapsed to its name until it is opened: a review of thirty files that opens them all is one
/// nobody reads to the end.
class _File extends StatefulWidget {
  const _File({required this.file});

  final ChangedFile file;

  @override
  State<_File> createState() => _FileState();
}

class _FileState extends State<_File> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.normal,
              vertical: Space.small,
            ),
            child: Row(
              children: <Widget>[
                Icon(_open ? Icons.expand_more : Icons.chevron_right,
                    size: Sizes.rowIcon),
                const SizedBox(width: Space.small),
                Expanded(
                  child: Text(
                    file.wasAt == null ? file.path : '${file.wasAt} → ${file.path}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                Text(file.what, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: Space.small),
                Text('+${file.insertions}',
                    style: TextStyle(color: scheme.primary, fontSize: 12)),
                const SizedBox(width: Space.tight),
                Text('−${file.deletions}',
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(Space.loose, 0, Space.normal, Space.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final line in file.lines) _Line(line: line),
              ],
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final DiffLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? background, Color? ink, String marker) = switch (line.kind) {
      DiffLineKind.added => (scheme.primaryContainer, scheme.onPrimaryContainer, '+'),
      DiffLineKind.removed => (scheme.errorContainer, scheme.onErrorContainer, '−'),
      DiffLineKind.hunk => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, ''),
      DiffLineKind.context => (null, null, ' '),
    };
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: Space.small, vertical: 1),
      child: SelectableText(
        '$marker${line.text}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: ink,
        ),
      ),
    );
  }
}

/// The decision, and the way to take the diff elsewhere.
class _Decision extends StatelessWidget {
  const _Decision({
    required this.gate,
    required this.onApprove,
    required this.onReject,
  });

  final Gate gate;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        padding: const EdgeInsets.all(Space.normal),
        child: Wrap(
          spacing: Space.small,
          runSpacing: Space.small,
          children: <Widget>[
            // First and plain: the common case is somebody wanting the diff in the tool they
            // review in, immediately. Nothing about it sends anything anywhere.
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined, size: Sizes.rowIcon),
              label: const Text('Copy the diff'),
              onPressed: gate.diff.isEmpty
                  ? null
                  : () => Clipboard.setData(ClipboardData(text: gate.diff)),
            ),
            OutlinedButton(
              onPressed: gate.looking == null ? null : onReject,
              child: const Text('Drop the request'),
            ),
            FilledButton(
              onPressed: gate.looking == null ? null : onApprove,
              child: const Text('Forward it upstream…'),
            ),
          ],
        ),
      );
}

/// Why the gate could not be read or acted on.
class GateProblem extends StatelessWidget {
  /// Constructor taking what to say.
  const GateProblem({required this.words, super.key});

  /// What went wrong, in words.
  final String words;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.all(Space.normal),
        child: Text(words, key: const Key('gate-problem')),
      );
}

/// Asks which branch to forward onto.
///
/// Named, never inferred: `Approve` requires a branch, and a push forwarded onto a guess is one
/// nobody decided about.
Future<String?> askWhichBranch(BuildContext context, {required String subject}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _WhichBranch(subject: subject),
    );

class _WhichBranch extends StatefulWidget {
  const _WhichBranch({required this.subject});

  final String subject;

  @override
  State<_WhichBranch> createState() => _WhichBranchState();
}

class _WhichBranchState extends State<_WhichBranch> {
  final _branch = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Forward it upstream'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.subject, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Space.normal),
              TextField(
                controller: _branch,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Branch to push to',
                  hintText: 'fix-rounding',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (branch) =>
                    Navigator.of(context).pop(branch.trim()),
              ),
              const SizedBox(height: Space.normal),
              Text(
                'This is the only thing the interface does that sends anything anywhere. '
                'The branch is named rather than guessed.',
                key: const Key('only-thing-that-sends'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final branch = _branch.text.trim();
              if (branch.isEmpty) return;
              Navigator.of(context).pop(branch);
            },
            child: const Text('Forward it'),
          ),
        ],
      );

  @override
  void dispose() {
    _branch.dispose();
    super.dispose();
  }
}
