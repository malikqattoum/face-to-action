import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/api_client.dart';
import '../models/log_model.dart';

class LogRepository {
  final ApiClient _client;

  LogRepository(this._client);

  Future<LogEntry> createLog(File audioFile, DateTime? recordedAt) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
      });

      final response = await _client.postFormData(ApiConstants.logs, formData);
      return LogEntry.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<LogEntry>> getLogs({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client.get(ApiConstants.logs, queryParameters: {
        'page': page,
        'per_page': perPage,
      });

      final List<dynamic> data = response.data['data'];
      return data.map((json) => LogEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LogEntry> getLog(int id) async {
    try {
      final response = await _client.get(ApiConstants.logById(id));
      return LogEntry.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LogEntry> updateLog(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(ApiConstants.logById(id), data: data);
      return LogEntry.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _client.delete(ApiConstants.logById(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Photo>> getPhotos(int logId) async {
    try {
      final response = await _client.get(ApiConstants.logPhotos(logId));
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Photo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Photo>> uploadPhotos(int logId, List<String> imagePaths, {String? caption}) async {
    try {
      final formData = FormData.fromMap({
        'photos': await Future.wait(
          imagePaths.map((path) => MultipartFile.fromFile(
            path,
            filename: path.split('/').last,
          )),
        ),
        if (caption != null) 'caption': caption,
      });

      final response = await _client.postFormData(
        ApiConstants.logPhotos(logId),
        formData,
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => Photo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePhoto(int logId, int photoId) async {
    try {
      await _client.delete('${ApiConstants.logPhotos(logId)}/$photoId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response!.data['message'];
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond.';
    }
    return 'Something went wrong. Please try again.';
  }
}
