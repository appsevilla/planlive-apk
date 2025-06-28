import 'package:flutter/material.dart';

class Styles {
  // Text Styles
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  static const TextStyle errorText = TextStyle(
    color: Colors.redAccent,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Input Decoration Theme
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Colors.grey),
  );

  // Button Styles
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    side: const BorderSide(color: Colors.deepPurple),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );
}
