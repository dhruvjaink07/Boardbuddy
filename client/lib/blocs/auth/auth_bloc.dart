import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import '../../repositories/mock_data.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(const AuthFailure('Please provide valid credentials'));
      return;
    }
    emit(const Authenticated(MockData.currentUser));
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(const AuthFailure('Please fill all fields'));
      return;
    }
    final newUser = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: event.email,
      displayName: event.displayName.isEmpty ? 'Dhruv' : event.displayName,
    );
    emit(Authenticated(newUser));
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 700));
    emit(const Authenticated(MockData.currentUser));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }
}
