import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller.dart';

/// Sign-up / log-in UI.
///
/// No business logic here — all auth calls go through [authControllerProvider].
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSignUp = false;
  var _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatAuthError(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final auth = ref.read(authControllerProvider.notifier);
      if (_isSignUp) {
        final response = await auth.signUpWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;

        // Supabase returns an obfuscated user with empty identities when the
        // email is already registered (confirm-email enabled). Do not reveal
        // that the address exists — use neutral copy instead.
        final identities = response.user?.identities;
        final obfuscatedExistingUser =
            identities != null && identities.isEmpty;

        setState(() {
          _isSignUp = false;
          _passwordController.clear();
          _info = obfuscatedExistingUser
              ? "We couldn't create your account. If you've already "
                  'registered, please sign in. Otherwise, check your email '
                  'for a verification link if you recently signed up.'
              : 'Verification email sent. Please check your inbox and verify '
                  'your email before signing in.';
        });
      } else {
        await auth.signInWithPassword(email: email, password: password);
        // Navigation is handled by go_router redirect on auth state change.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _formatAuthError(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tend',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create an account' : 'Sign in',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_info != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _info!,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'Sign up' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                              _info = null;
                            }),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : 'Need an account? Sign up',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
