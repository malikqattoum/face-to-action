import 'package:equatable/equatable.dart';
import '../../../data/models/call_session_model.dart';

enum CallsStatus { initial, loading, loaded, creating, error }

class CallsState extends Equatable {
  final CallsStatus status;
  final List<CallSession> calls;
  final String? errorMessage;

  const CallsState({
    this.status = CallsStatus.initial,
    this.calls = const [],
    this.errorMessage,
  });

  CallsState copyWith({CallsStatus? status, List<CallSession>? calls, String? errorMessage}) {
    return CallsState(
      status: status ?? this.status,
      calls: calls ?? this.calls,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, calls, errorMessage];
}
