import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/call_repository.dart';
import '../core/utils/api_client.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/logs/logs_bloc.dart';
import 'blocs/calls/calls_bloc.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/log_detail_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';
import 'pages/calls_page.dart';
import 'pages/add_call_page.dart';
import 'pages/call_detail_page.dart';

GoRouter createRouter(AuthBloc authBloc, CallsBloc callsBloc) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (authState.status == AuthStatus.initial) {
        authBloc.add(AuthCheckRequested());
      }

      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }
      if (authState.status == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/log/:id', builder: (_, state) => LogDetailPage(logId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/calls', builder: (_, __) => const CallsPage()),
      GoRoute(path: '/calls/add', builder: (_, __) => const AddCallPage()),
      GoRoute(path: '/calls/:id', builder: (_, state) => CallDetailPage(callId: int.parse(state.pathParameters['id']!))),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
