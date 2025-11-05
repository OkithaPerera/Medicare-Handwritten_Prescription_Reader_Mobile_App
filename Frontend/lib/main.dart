import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicare/screens/home_screen.dart';
import 'package:medicare/screens/login_screen.dart';
import 'package:medicare/screens/profile_screen.dart';
import 'package:medicare/screens/registration_screen.dart';
import 'package:medicare/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicare',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 18.0, color: Colors.teal.shade800),
          titleLarge: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008037)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
