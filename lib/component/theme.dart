import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade200,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: Colors.black, // Set text color to black in light mode
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Colors.black,
    primary: Colors.grey.shade800,
    secondary: Colors.grey.shade700,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: Colors.white, // Set text color to black in light mode
    ),
  ),
);
