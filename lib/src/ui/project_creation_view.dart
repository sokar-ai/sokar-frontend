import 'package:flutter/material.dart';
import '../app/project_creation.dart';
import 'tokens.dart';

/// Describes a project, checks it against the machine, and creates it.
///
/// **Every question in one place, and every answer checked by the machine that will run it.** A
/// name that does not survive becoming an image tag, a set that is not installed there, a class
/// spelled wrong — none of that can be judged here, and an answer accepted in this dialog and
/// refused at the first task start is refused far from where it was given.
///
/// **Nothing is written until the last press.** Every check runs with `dryRun`, so a flow somebody
/// walks away from leaves nothing behind.
Future<bool> createAProject(
  BuildContext context, {
  required ProjectCreation creation,
  required List<String> setsHere,
  required VoidCallback onCheck,
  required Future<void> Function() onCreate,
}) async {
  final made = await showDialog<bool>(
    context: context,
    builder: (context) => _CreateProjectDialog(
      creation: creation,
      setsHere: setsHere,
      onCheck: onCheck,
      onCreate: onCreate,
    ),
  );
  return made ?? false;
}

class _CreateProjectDialog extends StatelessWidget {
  const _CreateProjectDialog({
    required this.creation,
    required this.setsHere,
    required this.onCheck,
    required this.onCreate,
  });

  final ProjectCreation creation;
  final List<String> setsHere;
  final VoidCallback onCheck;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: creation,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          final made = creation.created;

          return AlertDialog(
            title: Text(made?.written ?? false ? 'Created' : 'Describe a project'),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (creation.problem != null)
                      _Block(
                        colour: scheme.errorContainer,
                        child: Text(creation.problem!,
                            key: const Key('creation-problem')),
                      )
                    else if (made != null)
                      _Block(
                        colour: made.written
                            ? scheme.surfaceContainerHighest
                            : scheme.errorContainer,
                        child: Text(creation.words, key: const Key('creation-says')),
                      ),
                    if (!(made?.written ?? false)) ...<Widget>[
                      _Answer(
                        id: 'project-file',
                        label: 'Where the project file goes',
                        hint: '/srv/checkout/project.yml',
                        value: creation.file,
                        onChanged: (typed) => creation.answer(() => creation.file = typed),
                      ),
                      _Answer(
                        id: 'project-name',
                        label: 'What it is called',
                        hint: 'checkout',
                        value: creation.name,
                        onChanged: (typed) => creation.answer(() => creation.name = typed),
                      ),
                      const SizedBox(height: Space.small),
                      Text('What its work may reach',
                          style: Theme.of(context).textTheme.labelLarge),
                      // **Nothing preselected.** The class decides what work here may reach, and
                      // a default would be a decision nobody made. `RadioGroup` is content with
                      // an empty selection, which is the behaviour wanted rather than a gap.
                      RadioGroup<String>(
                        groupValue:
                            creation.securityClass.isEmpty ? null : creation.securityClass,
                        onChanged: (chosen) => creation.answer(
                            () => creation.securityClass = chosen ?? ''),
                        child: Column(
                          children: <Widget>[
                            for (final (klass, what) in const <(String, String)>[
                              ('offline', 'reaches nothing at all'),
                              ('guarded',
                                  'reaches what the project declares, through the gate'),
                              ('online', 'pushes to its upstream directly'),
                            ])
                              RadioListTile<String>(
                                key: Key('class-$klass'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: klass,
                                title: Text('$klass — $what'),
                              ),
                          ],
                        ),
                      ),
                      _Answer(
                        id: 'base-image',
                        label: 'What its image is built from',
                        hint: 'ubuntu:24.04',
                        value: creation.baseImage,
                        onChanged: (typed) => creation.answer(() => creation.baseImage = typed),
                      ),
                      if (creation.securityClass == 'online')
                        _Answer(
                          id: 'upstream',
                          label: 'Where it pushes',
                          hint: 'git@example.test:team/checkout.git',
                          value: creation.upstream,
                          onChanged: (typed) =>
                              creation.answer(() => creation.upstream = typed),
                        ),
                      if (setsHere.isNotEmpty) ...<Widget>[
                        const SizedBox(height: Space.small),
                        Text('Destinations it starts with',
                            style: Theme.of(context).textTheme.labelLarge),
                        // The sets this machine actually has, rather than a list typed from
                        // memory — one that is not installed there is a refusal waiting.
                        Wrap(
                          spacing: Space.small,
                          children: <Widget>[
                            for (final set in setsHere)
                              FilterChip(
                                key: Key('set-$set'),
                                label: Text(set),
                                selected: creation.sets.contains(set),
                                onSelected: (chosen) => creation.answer(
                                  () => chosen
                                      ? creation.sets.add(set)
                                      : creation.sets.remove(set),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (creation.refusals.isNotEmpty) ...<Widget>[
                        const SizedBox(height: Space.normal),
                        _Block(
                          colour: scheme.errorContainer,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('The machine will not take these',
                                  style: Theme.of(context).textTheme.labelLarge),
                              for (final problem in creation.refusals)
                                Padding(
                                  padding: const EdgeInsets.only(top: Space.tight),
                                  child: Text('${problem.field}: ${problem.what}',
                                      key: const Key('refusal')),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (creation.warnings.isNotEmpty) ...<Widget>[
                        const SizedBox(height: Space.normal),
                        // Worth showing and not worth blocking on: a base image that is not there
                        // yet will simply be pulled, and refusing would turn a note into a wall.
                        _Block(
                          colour: scheme.surfaceContainerHighest,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Worth knowing, and not in the way',
                                  style: Theme.of(context).textTheme.labelLarge),
                              for (final problem in creation.warnings)
                                Padding(
                                  padding: const EdgeInsets.only(top: Space.tight),
                                  child: Text('${problem.field}: ${problem.what}',
                                      key: const Key('warning')),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (creation.content.isNotEmpty) ...<Widget>[
                        const SizedBox(height: Space.normal),
                        Text('What would be written',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: Space.tight),
                        // Shown before anything is created, and filled even on a refusal —
                        // seeing what was rejected is most of understanding why.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Space.small),
                          color: scheme.surfaceContainerLowest,
                          child: SelectableText(creation.content,
                              key: const Key('what-would-be-written'),
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12)),
                        ),
                        const SizedBox(height: Space.tight),
                        Text(
                          'It is an ordinary file. Anything this dialog does not ask about is '
                          'edited in it afterwards.',
                          key: const Key('an-ordinary-file'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              if (made?.written ?? false)
                FilledButton(
                  key: const Key('done-creating'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Right'),
                )
              else ...<Widget>[
                TextButton(
                  key: const Key('abandon-creating'),
                  onPressed: () => Navigator.of(context).pop(false),
                  // Nothing has been written, so leaving costs nothing and needs no warning.
                  child: const Text('Leave it'),
                ),
                FilledButton(
                  key: const Key('create-the-project'),
                  onPressed: creation.busy || !creation.canBeCreated
                      ? null
                      : () async => onCreate(),
                  child: const Text('Create it'),
                ),
              ],
            ],
          );
        },
      );
}

class _Answer extends StatefulWidget {
  const _Answer({
    required this.id,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String label;
  final String hint;
  final String value;
  final void Function(String) onChanged;

  @override
  State<_Answer> createState() => _AnswerState();
}

class _AnswerState extends State<_Answer> {
  late final TextEditingController _typed =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.tight),
        child: TextField(
          key: Key(widget.id),
          controller: _typed,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
        ),
      );
}

class _Block extends StatelessWidget {
  const _Block({required this.colour, required this.child});

  final Color colour;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Space.small),
        padding: const EdgeInsets.all(Space.normal),
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: child,
      );
}
