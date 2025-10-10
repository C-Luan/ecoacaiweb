import 'package:ecoacaiweb/firebase_options.dart';
import 'package:ecoacaiweb/screens/auth_wrapper.dart';
import 'package:ecoacaiweb/screens/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoAçaí Web',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const  Color.fromARGB(255, 25, 52, 95), // Cor primária roxo escuro
          primary: const  Color.fromARGB(255, 25, 52, 95),
          secondary: const Color(0xFF059669), // Cor secundária verde
          onSurface: const Color(0xFF374151), // Cor de texto cinza
        ),
        useMaterial3: false,
        // Define a fonte ui-rounded, se disponível no sistema, ou Roboto.
        fontFamily: 'ui-rounded',
        textTheme: const TextTheme(
          // Define a cor padrão para o texto em todo o aplicativo.
          bodyLarge: TextStyle(color: Color(0xFF374151)),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
          titleLarge: TextStyle(color: Color(0xFF374151)),
          headlineMedium: TextStyle(color: Color(0xFF374151)),
          headlineLarge: TextStyle(color: Color(0xFF374151)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Fundo branco para AppBars
          foregroundColor: Color(0xFF374151), // Cor do texto e ícones na AppBar
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // Fundo levemente cinza para inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none, // Remove a borda padrão
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          labelStyle: const TextStyle(color: Color(0xFF374151)),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
