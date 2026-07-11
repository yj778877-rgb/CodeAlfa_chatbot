import 'package:flutter/material.dart';

import 'chat_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrewBlissApp());
}

class BrewBlissApp extends StatelessWidget {
  const BrewBlissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brew & Bliss Café',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5EEE4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B2E1E),
          primary: const Color(0xFF4B2E1E),
          secondary: const Color(0xFF6F4E37),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
