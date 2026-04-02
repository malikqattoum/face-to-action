import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/log_repository.dart';
import 'data/repositories/call_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/logs/logs_bloc.dart';
import 'presentation/blocs/calls/calls_bloc.dart';
import 'presentation/router.dart';

void main() {
  runApp(const FaceToActionApp());
}

class FaceToActionApp extends StatefulWidget {
  const FaceToActionApp({super.key});

  @override
  State<FaceToActionApp> createState() => _FaceToActionAppState();
}

class _FaceToActionAppState extends State<FaceToActionApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final LogRepository _logRepository;
  late final CallRepository _callRepository;
  late final AuthBloc _authBloc;
  late final LogsBloc _logsBloc;
  late final CallsBloc _callsBloc;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepository = AuthRepository(_apiClient);
    _logRepository = LogRepository(_apiClient);
    _callRepository = CallRepository(_apiClient);
    _authBloc = AuthBloc(_authRepository)..add(AuthCheckRequested());
    _logsBloc = LogsBloc(_logRepository);
    _callsBloc = CallsBloc(_callRepository);

    // Handle 401 Unauthorized — redirect to login
    _apiClient.onUnauthorized = () {
      _authBloc.add(AuthLogoutRequested());
    };
  }

  @override
  void dispose() {
    _authBloc.close();
    _logsBloc.close();
    _callsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<LogsBloc>.value(value: _logsBloc),
        BlocProvider<CallsBloc>.value(value: _callsBloc),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return MaterialApp.router(
            title: 'Face-to-Action',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: createRouter(_authBloc, _callsBloc),
          );
        },
      ),
    );
  }
}
