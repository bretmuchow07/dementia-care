import 'package:dementia_care/screens/auth/auth_gate.dart';
import 'package:dementia_care/home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize the Gemini package with your API key
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY']!);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (accessToken != null && refreshToken != null) {
      try {
        await Supabase.instance.client.auth.setSession(accessToken);
        _isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      } catch (e) {
        print('Session restore failed: $e');
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dementia Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: const Color(0xFFF1F8FA),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isAuthenticated
              ? const HomePage() // Replace with your actual home screen
              : const AuthGate(),  // Goes to login/register screen
    );
  }
}
