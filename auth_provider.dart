import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return await ref.watch(firebaseServiceProvider).isAdmin();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseService _service;

  AuthNotifier(this._service) : super(const AsyncValue.loading());

  Future<bool> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _service.signIn(email, password);
      state = AsyncValue.data(_service.currentUser);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      state = const AsyncValue.loading();
      await _service.register(email, password, name);
      state = AsyncValue.data(_service.currentUser);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(firebaseServiceProvider));
});
