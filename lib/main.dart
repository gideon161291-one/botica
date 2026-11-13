import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eukhiivwdhyitdukrxln.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1a2hpaXZ3ZGh5aXRkdWtyeGxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1OTc3ODAsImV4cCI6MjA5NTE3Mzc4MH0.8H4N3IRGhXVSpTo8b1wC9HdaDIzhEsJWvKUScd00YDw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplicativo G.one',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primarySwatch: Colors.cyan,
      ),
      home: const LoginScreen(),
    );
  }
}