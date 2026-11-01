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

/// Shows email/password sign-in until a user is signed in, then [child].
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
          return const _Shell(child: Center(child: CircularProgressIndicator()));
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
            fontFamily: 'InspectionSans'),
        home: Scaffold(body: child),
      );
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false, _busy = false, _hidden = true;
  String? _error, _info;

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Email or password is incorrect.',
        'email-already-in-use' =>
          'An account already exists for this email. Sign in instead.',
        'weak-password' => 'Use at least 8 characters for your password.',
        'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        _ => 'Something went wrong. Please try again.',
      };

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = FirebaseAuth.instance;
    try {
      if (_creating) {
        await auth.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      } else {
        await auth.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = 'Enter your email above, then tap Forgot password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        if (mounted) setState(() => _error = _message(e));
        return;
      }
    }
    // Same message either way, so the screen does not reveal which emails exist.
    if (mounted) {
      setState(() {
        _error = null;
        _info = 'If an account exists for $email, a reset link is on its way.';
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF15121A),
        labelStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9B6BFF), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) => _Shell(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.flight_rounded, size: 40, color: Colors.white),
                        const SizedBox(height: 18),
                        Text(_creating ? 'Create your account' : 'Welcome back',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 26,
                                letterSpacing: -0.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Pluto Inspector',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.white54)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: _field('Email'),
                          validator: (v) => _emailPattern.hasMatch((v ?? '').trim())
                              ? null
                              : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidden,
                          autofillHints: [
                            _creating ? AutofillHints.newPassword : AutofillHints.password
                          ],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: const TextStyle(color: Colors.white),
                          decoration: _field('Password',
                              suffix: IconButton(
                                  tooltip: _hidden ? 'Show password' : 'Hide password',
                                  icon: Icon(
                                      _hidden
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white54),
                                  onPressed: () => setState(() => _hidden = !_hidden))),
                          validator: (v) {
                            final p = v ?? '';
                            if (p.isEmpty) return 'Enter your password';
                            if (_creating && p.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        if (!_creating)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: _busy ? null : _reset,
                                child: const Text('Forgot password?',
                                    style: TextStyle(color: Color(0xFFB794FF)))),
                          )
                        else
                          const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder()),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_creating ? 'Create account' : 'Sign in',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        if (_error != null || _info != null) ...[
                          const SizedBox(height: 14),
                          Text(_error ?? _info!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: _error != null
                                      ? const Color(0xFFFF8A8A)
                                      : Colors.white70,
                                  fontSize: 13.5)),
                        ],
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _creating = !_creating;
                                    _error = null;
                                    _info = null;
                                  }),
                          child: Text(
                              _creating
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ]),
                ),
              ),
            ),
          ),
        ),
      );
}
