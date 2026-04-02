import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class LogsEvent extends Equatable {
  const LogsEvent();

  @override
  List<Object?> get props => [];
}

class LogsFetchRequested extends LogsEvent {}

class LogCreateRequested extends LogsEvent {
  final File audioFile;
  final DateTime? recordedAt;

  const LogCreateRequested({required this.audioFile, this.recordedAt});

  @override
  List<Object?> get props => [audioFile, recordedAt];
}

class LogUpdateRequested extends LogsEvent {
  final int id;
  final Map<String, dynamic> data;

  const LogUpdateRequested({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class LogDeleteRequested extends LogsEvent {
  final int id;

  const LogDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class LogPhotosUploaded extends LogsEvent {
  final int logId;
  final List<String> imagePaths;
  final String? caption;

  const LogPhotosUploaded({required this.logId, required this.imagePaths, this.caption});

  @override
  List<Object?> get props => [logId, imagePaths, caption];
}
