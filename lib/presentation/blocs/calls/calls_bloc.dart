import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/call_repository.dart';
import 'calls_event.dart';
import 'calls_state.dart';

class CallsBloc extends Bloc<CallsEvent, CallsState> {
  final CallRepository _callRepository;

  CallsBloc(this._callRepository) : super(const CallsState()) {
    on<CallsFetchRequested>(_onFetchRequested);
    on<CallCreateRequested>(_onCreateRequested);
    on<CallCreateWithMemoRequested>(_onCreateWithMemoRequested);
    on<CallUpdateRequested>(_onUpdateRequested);
    on<CallDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onFetchRequested(CallsFetchRequested event, Emitter<CallsState> emit) async {
    emit(state.copyWith(status: CallsStatus.loading));
    try {
      final calls = await _callRepository.getCalls();
      emit(state.copyWith(status: CallsStatus.loaded, calls: calls));
    } catch (e) {
      emit(state.copyWith(status: CallsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateRequested(CallCreateRequested event, Emitter<CallsState> emit) async {
    emit(state.copyWith(status: CallsStatus.creating));
    try {
      final call = await _callRepository.createCall(event.data);
      final updatedCalls = [call, ...state.calls];
      emit(state.copyWith(status: CallsStatus.loaded, calls: updatedCalls));
    } catch (e) {
      emit(state.copyWith(status: CallsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateWithMemoRequested(CallCreateWithMemoRequested event, Emitter<CallsState> emit) async {
    emit(state.copyWith(status: CallsStatus.creating));
    try {
      final call = await _callRepository.createCallWithMemo(event.data, event.audioFile);
      final updatedCalls = [call, ...state.calls];
      emit(state.copyWith(status: CallsStatus.loaded, calls: updatedCalls));
    } catch (e) {
      emit(state.copyWith(status: CallsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(CallUpdateRequested event, Emitter<CallsState> emit) async {
    emit(state.copyWith(status: CallsStatus.loading));
    try {
      final updatedCall = await _callRepository.updateCall(event.id, event.data);
      final updatedCalls = state.calls.map((c) => c.id == event.id ? updatedCall : c).toList();
      emit(state.copyWith(status: CallsStatus.loaded, calls: updatedCalls));
    } catch (e) {
      emit(state.copyWith(status: CallsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(CallDeleteRequested event, Emitter<CallsState> emit) async {
    emit(state.copyWith(status: CallsStatus.loading));
    try {
      await _callRepository.deleteCall(event.id);
      final updatedCalls = state.calls.where((c) => c.id != event.id).toList();
      emit(state.copyWith(status: CallsStatus.loaded, calls: updatedCalls));
    } catch (e) {
      emit(state.copyWith(status: CallsStatus.error, errorMessage: e.toString()));
    }
  }
}
