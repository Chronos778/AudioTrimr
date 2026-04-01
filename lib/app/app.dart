import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/trimmer/screen/trimmer_screen.dart';

class TrimrApp extends StatelessWidget {
  const TrimrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRIMR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const TrimmerScreen(),
    );
  }
}
