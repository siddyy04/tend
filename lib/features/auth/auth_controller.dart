import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// High-level auth status used by the router for redirects.
enum AuthStatus {
  /// Session check has not finished yet — show splash.
  loading,

  /// Valid Supabase session present.
  authenticated,

  /// No active session.
  unauthenticated,
}

/// App-level auth view-state for the router and auth UI.
///
/// Named [AppAuthState] to avoid clashing with gotrue's [AuthState].
class AppAuthState {
  const AppAuthState({
    required this.status,
    this.session,
  });

  final AuthStatus status;
  final Session? session;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Auth business logic — session hydration and Supabase Auth only.
///
/// No Supabase table queries. Widgets must call methods here rather than
/// touching [Supabase.instance] directly.
class AuthController extends Notifier<AppAuthState> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AppAuthState build() {
    ref.onDispose(() {
      unawaited(_authSubscription?.cancel());
    });

    // Emit loading first so the router can show splash, then hydrate.
    Future.microtask(_hydrate);

    return const AppAuthState(status: AuthStatus.loading);
  }

  Future<void> _hydrate() async {
    final auth = Supabase.instance.client.auth;
    _applySession(auth.currentSession);

    await _authSubscription?.cancel();
    _authSubscription = auth.onAuthStateChange.listen((data) {
      _applySession(data.session);
    });
  }

  void _applySession(Session? session) {
    state = AppAuthState(
      status: session != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      session: session,
    );
  }

  /// Email/password sign-in (Sprint 0 auth screen).
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Email/password sign-up (Sprint 0 auth screen).
  ///
  /// Returns the [AuthResponse] so the UI can distinguish a real signup from
  /// Supabase's obfuscated existing-user response (empty [User.identities])
  /// without revealing whether the email is registered.
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AppAuthState>(AuthController.new);
