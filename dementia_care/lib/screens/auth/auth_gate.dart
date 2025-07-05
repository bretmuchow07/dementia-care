import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:dementia_care/screens/auth/login.dart';
import 'package:dementia_care/home.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        // Show loading spinner while waiting for the stream to connect
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Listen to sign-in/sign-out events
        if (snapshot.hasData) {
          final authChange = snapshot.data!.event;
          final newSession = snapshot.data!.session;

          if (authChange == AuthChangeEvent.signedIn && newSession != null) {
            // Save tokens securely
            _storage.write(key: 'access_token', value: newSession.accessToken);
            _storage.write(key: 'refresh_token', value: newSession.refreshToken);

            return const HomePage();
          }

          if (authChange == AuthChangeEvent.signedOut) {
            _storage.deleteAll(); // optional cleanup
            return const LoginPage();
          }
        }

        // Fallback: check current session directly
        if (session != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
