import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CallsEvent extends Equatable {
  const CallsEvent();
  @override
  List<Object?> get props => [];
}

class CallsFetchRequested extends CallsEvent {}

class CallCreateRequested extends CallsEvent {
  final Map<String, dynamic> data;
  const CallCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class CallCreateWithMemoRequested extends CallsEvent {
  final Map<String, dynamic> data;
  final File audioFile;
  const CallCreateWithMemoRequested({required this.data, required this.audioFile});
  @override
  List<Object?> get props => [data, audioFile];
}

class CallUpdateRequested extends CallsEvent {
  final int id;
  final Map<String, dynamic> data;
  const CallUpdateRequested({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}

class CallDeleteRequested extends CallsEvent {
  final int id;
  const CallDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
