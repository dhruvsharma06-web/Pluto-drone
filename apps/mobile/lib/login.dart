import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// True once Firebase initialised from android/app/google-services.json.
bool firebaseReady = false;

Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // No Firebase config packaged: the app runs without sign-in.
    firebaseReady = false;
  }
}

/// Current user's ID token for the explain proxy, or null when signed out.
Future<String?> idToken() async =>
    firebaseReady ? FirebaseAuth.instance.currentUser?.getIdToken() : null;

/// Shows Google Sign-In until a user is signed in, then [child].
class LoginGate extends StatelessWidget {
  const LoginGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) return child;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Shell(child: CircularProgressIndicator());
        }
        return snap.data == null ? const _LoginScreen() : child;
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            fontFamily: 'Inter'),
        home: Scaffold(body: Center(child: child)),
      );
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Sign-in failed.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Shell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.flight, size: 48, color: Colors.white),
            const SizedBox(height: 20),
            const Text('Pluto Inspector',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Sign in to inspect your drone',
                style: TextStyle(fontSize: 15, color: Colors.white60)),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder()),
                onPressed: _busy ? null : _signIn,
                icon: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: Text(_busy ? 'Signing in…' : 'Continue with Google',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            ],
          ]),
        ),
      );
}
