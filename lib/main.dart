import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/_widget_gallery_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '憶智防線',
      theme: AppTheme.lightTheme,
      home: const WidgetGalleryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}