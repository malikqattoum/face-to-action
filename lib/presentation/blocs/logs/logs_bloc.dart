import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/log_repository.dart';
import 'logs_event.dart';
import 'logs_state.dart';

class LogsBloc extends Bloc<LogsEvent, LogsState> {
  final LogRepository _logRepository;

  LogsBloc(this._logRepository) : super(const LogsState()) {
    on<LogsFetchRequested>(_onFetchRequested);
    on<LogCreateRequested>(_onCreateRequested);
    on<LogUpdateRequested>(_onUpdateRequested);
    on<LogDeleteRequested>(_onDeleteRequested);
    on<LogPhotosUploaded>(_onPhotosUploaded);
  }

  Future<void> _onFetchRequested(LogsFetchRequested event, Emitter<LogsState> emit) async {
    emit(state.copyWith(status: LogsStatus.loading));
    try {
      final logs = await _logRepository.getLogs();
      emit(state.copyWith(status: LogsStatus.loaded, logs: logs));
    } catch (e) {
      emit(state.copyWith(status: LogsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateRequested(LogCreateRequested event, Emitter<LogsState> emit) async {
    emit(state.copyWith(status: LogsStatus.creating));
    try {
      final log = await _logRepository.createLog(event.audioFile, event.recordedAt);
      final updatedLogs = [log, ...state.logs];
      emit(state.copyWith(status: LogsStatus.created, logs: updatedLogs, lastCreatedLog: log));
    } catch (e) {
      emit(state.copyWith(status: LogsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(LogUpdateRequested event, Emitter<LogsState> emit) async {
    emit(state.copyWith(status: LogsStatus.updating));
    try {
      final updatedLog = await _logRepository.updateLog(event.id, event.data);
      final updatedLogs = state.logs.map((l) => l.id == event.id ? updatedLog : l).toList();
      emit(state.copyWith(status: LogsStatus.loaded, logs: updatedLogs));
    } catch (e) {
      emit(state.copyWith(status: LogsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(LogDeleteRequested event, Emitter<LogsState> emit) async {
    emit(state.copyWith(status: LogsStatus.loading));
    try {
      await _logRepository.deleteLog(event.id);
      final updatedLogs = state.logs.where((l) => l.id != event.id).toList();
      emit(state.copyWith(status: LogsStatus.loaded, logs: updatedLogs));
    } catch (e) {
      emit(state.copyWith(status: LogsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onPhotosUploaded(LogPhotosUploaded event, Emitter<LogsState> emit) async {
    try {
      final newPhotos = await _logRepository.uploadPhotos(event.logId, event.imagePaths, caption: event.caption);
      final updatedLogs = state.logs.map((l) {
        if (l.id == event.logId) {
          return l.copyWith(photos: [...l.photos, ...newPhotos]);
        }
        return l;
      }).toList();
      emit(state.copyWith(status: LogsStatus.loaded, logs: updatedLogs));
    } catch (e) {
      emit(state.copyWith(status: LogsStatus.error, errorMessage: e.toString()));
    }
  }
}
