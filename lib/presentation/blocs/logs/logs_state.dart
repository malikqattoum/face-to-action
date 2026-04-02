import 'package:equatable/equatable.dart';
import '../../../data/models/log_model.dart';

enum LogsStatus { initial, loading, loaded, creating, created, updating, error }

class LogsState extends Equatable {
  final LogsStatus status;
  final List<LogEntry> logs;
  final LogEntry? lastCreatedLog;
  final String? errorMessage;

  const LogsState({
    this.status = LogsStatus.initial,
    this.logs = const [],
    this.lastCreatedLog,
    this.errorMessage,
  });

  LogsState copyWith({
    LogsStatus? status,
    List<LogEntry>? logs,
    LogEntry? lastCreatedLog,
    String? errorMessage,
  }) {
    return LogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      lastCreatedLog: lastCreatedLog ?? this.lastCreatedLog,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, logs, lastCreatedLog, errorMessage];
}
