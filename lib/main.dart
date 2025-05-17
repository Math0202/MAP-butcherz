import 'package:flutter/material.dart';
import 'package:hocky_na_org/On%20Boarding/Onboarding.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MongoDB connection
  await MongoDBService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hocky.na',

      // --- Light Theme Definition ---
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.grey[100]!,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          centerTitle: true,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.black87, height: 1.5),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue, width: 1.5),
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.black54),
          prefixIconColor: Colors.black54,
          suffixIconColor: Colors.black54,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        ),
        checkboxTheme: CheckboxThemeData(
          side: const BorderSide(color: Colors.black54),
          checkColor: MaterialStateProperty.all(Colors.white),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue;
            }
            return Colors.transparent;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        useMaterial3: true,
      ),

      // --- Dark Theme Definition ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[300]!,
          secondary: Colors.blueAccent[100]!,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white70,
          onSurface: Colors.white70,
          error: Colors.redAccent[100]!,
          onError: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white70,
          elevation: 1,
          centerTitle: true,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white70, height: 1.5),
          labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue[300]!,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue[300]!, width: 1.5),
            foregroundColor: Colors.blue[300]!,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIconColor: Colors.grey[500],
          suffixIconColor: Colors.grey[500],
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        ),
        checkboxTheme: CheckboxThemeData(
          side: BorderSide(color: Colors.grey[500]!),
          checkColor: MaterialStateProperty.all(Colors.black),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue[300]!;
            }
            return Colors.transparent;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        useMaterial3: true,
      ),

      // --- Theme Mode ---
      themeMode: ThemeMode.system,

      home: const Onboarding(),
    );
  }
}
