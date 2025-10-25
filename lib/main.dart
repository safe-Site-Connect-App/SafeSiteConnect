import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safesiteconnect/navigation/route.dart';

// Providers
import 'Provider/Providertheme.dart';
import 'ViewsModels/alerte_viewmodel.dart';
import 'ViewsModels/auth_viewmodel.dart';
import 'ViewsModels/pointage_viewmodel.dart';
import 'ViewsModels/tache_viewmodel.dart';
import 'ViewsModels/user_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PointageViewModel()),
        ChangeNotifierProvider(create: (_) => AlerteViewModel()),
        ChangeNotifierProvider(create: (_) => TacheViewModel()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SafeSiteConnect',
      debugShowCheckedModeBanner: false,

      // Thèmes
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,

      // Routes
      initialRoute: AppRoutes.signIn,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  // Thème clair
  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005B96),
        primary: const Color(0xFF005B96),
        secondary: const Color(0xFF28A745),
        background: const Color(0xFFF0F0F0),
        surface: const Color(0xFFFFFFFF),
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFFFFFFFF),
        onBackground: const Color(0xFF333333),
        onSurface: const Color(0xFF333333),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28A745),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF005B96),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF005B96)),
        ),
        labelStyle: const TextStyle(color: Color(0xFF333333)),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF005B96),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Thème sombre
  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005B96),
        primary: const Color(0xFF007ACC),
        secondary: const Color(0xFF28A745),
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white70,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28A745),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00BFFF),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00BFFF)),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF005B96),
        foregroundColor: Colors.white,
      ),
    );
  }
}
