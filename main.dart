import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QuizGeneratorApp());
}

class QuizGeneratorApp extends StatelessWidget {
  const QuizGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const double fontScale = 1.8;

    return MaterialApp(
      title: 'Quiz Generator AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          primary: const Color(0xFF673AB7),
          surface: const Color(0xFFFBFBFE),
        ),
        scaffoldBackgroundColor: const Color(0xFFFBFBFE),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        textTheme: _buildTextTheme(fontScale, Colors.black87),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: const Color(0xFF673AB7).withValues(alpha: 0.4),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }

  TextTheme _buildTextTheme(double scale, Color color) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * 0.7 * scale, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
      displayMedium: TextStyle(fontSize: 45 * 0.7 * scale, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 36 * 0.7 * scale, fontWeight: FontWeight.bold, color: color),
      headlineLarge: TextStyle(fontSize: 32 * 0.7 * scale, fontWeight: FontWeight.w800, color: color),
      headlineMedium: TextStyle(fontSize: 28 * 0.7 * scale, fontWeight: FontWeight.bold, color: color),
      headlineSmall: TextStyle(fontSize: 24 * 0.7 * scale, fontWeight: FontWeight.bold, color: color),
      titleLarge: TextStyle(fontSize: 22 * 0.7 * scale, fontWeight: FontWeight.bold, color: color),
      titleMedium: TextStyle(fontSize: 16 * 0.7 * scale, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontSize: 14 * 0.7 * scale, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontSize: 16 * scale, height: 1.5, color: color),
      bodyMedium: TextStyle(fontSize: 14 * scale, height: 1.5, color: color),
      bodySmall: TextStyle(fontSize: 12 * scale, height: 1.4, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold, color: color),
    );
  }
}
