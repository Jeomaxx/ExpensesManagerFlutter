import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._userRepository, this._secureStorage) 
      : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId != null) {
        final user = await _userRepository.getUserById(userId);
        if (user != null) {
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          return;
        }
      }
      
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // TODO: Implement actual authentication with Firebase Auth or local auth
      final user = await _userRepository.getUserByEmail(email);
      
      if (user != null) {
        await _secureStorage.write(key: 'user_id', value: user.id);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          error: 'Invalid credentials',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Check if user already exists
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser != null) {
        state = state.copyWith(
          error: 'User already exists',
          isLoading: false,
        );
        return false;
      }

      // Create new user
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        settings: {
          'currency': 'SAR',
          'language': 'ar',
          'theme': 'light',
          'notifications': true,
        },
        createdAt: now,
        lastModified: now,
      );

      await _userRepository.createUser(user);
      await _secureStorage.write(key: 'user_id', value: user.id);
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: 'user_id');
    state = const AuthState();
  }

  Future<void> updateUser(User user) async {
    try {
      await _userRepository.updateUser(user);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(userRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});