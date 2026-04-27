import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/workspace/presentation/main_workspace.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: VizXpertApp()));
}

class VizXpertApp extends StatelessWidget {
  const VizXpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VizXpert — Audio Visualizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainWorkspace(),
    );
  }
}
