import 'package:flutter/material.dart';

void main() => runApp(const SokarFrontendApp());

/// The application shell, which is [F01](../requirements/F01-Application-Shell.md)'s subject and
/// is not built yet. This exists so the scaffold compiles, runs and can be packaged; replace it,
/// do not build around it.
class SokarFrontendApp extends StatelessWidget {
  const SokarFrontendApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sokar',
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const Scaffold(
          body: Center(child: Text('Nothing is built yet.')),
        ),
      );
}
