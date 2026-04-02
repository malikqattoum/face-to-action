import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/api_client.dart';
import '../models/call_session_model.dart';

class CallRepository {
  final ApiClient _client;

  CallRepository(this._client);

  Future<List<CallSession>> getCalls({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client.get(ApiConstants.calls, queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      final List<dynamic> data = response.data['data'];
      return data.map((json) => CallSession.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CallSession> createCall(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.calls, data: data);
      return CallSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CallSession> getCall(int id) async {
    try {
      final response = await _client.get(ApiConstants.callById(id));
      return CallSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CallSession> updateCall(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(ApiConstants.callById(id), data: data);
      return CallSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteCall(int id) async {
    try {
      await _client.delete(ApiConstants.callById(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CallSession> attachMemo(int id) async {
    try {
      final response = await _client.post(ApiConstants.callAttachMemo(id));
      return CallSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create call + immediately attach voice memo audio
  Future<CallSession> createCallWithMemo(Map<String, dynamic> callData, File audioFile) async {
    try {
      // Create the call session first
      final call = await createCall(callData);
      // Upload memo audio via logs endpoint (reuses audio upload)
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioFile.path, filename: audioFile.path.split('/').last),
        'notes': 'Attached to call #${call.id}',
      });
      await _client.postFormData('/logs', formData);
      // Mark call as having memo
      return await attachMemo(call.id);
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
