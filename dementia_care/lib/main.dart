import 'package:dementia_care/screens/auth/auth_gate.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knlyoklxzbxlunxhsrda.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtubHlva2x4emJ4bHVueGhzcmRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk3Nzg4MzAsImV4cCI6MjA1NTM1NDgzMH0.A6GfEbsuMK6SIK0N-J8gMO85xJ2xwwztulK7ybbiSA0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dementia Care',
      home: const AuthGate(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: const Color(0xFFF1F8FA), // Set the background color here
      ),
    );
  }
}


