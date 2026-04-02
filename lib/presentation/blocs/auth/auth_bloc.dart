import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await _authRepository.login(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await _authRepository.register(event.name, event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.logout();
    } finally {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
