import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/scan_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PhudBoxApp());
}

class PhudBoxApp extends StatelessWidget {
  const PhudBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'PHUD BOX',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const ScanScreen(),
      ),
    );
  }
}
