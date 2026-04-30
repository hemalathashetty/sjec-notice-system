import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<void> saveUserInfo(String role, String fullName) async {
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'full_name', value: fullName);
  }

  static Future<void> saveUserId(int id) async {
    await _storage.write(key: 'user_id', value: id.toString());
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final role = await _storage.read(key: 'role');
    final fullName = await _storage.read(key: 'full_name');
    return {'role': role, 'full_name': fullName};
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        '${Constants.baseUrl}/auth/me',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch user details';
      return {'success': false, 'message': message};
    }
  }

  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        Constants.loginUrl,
        data: {'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Login failed';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getMyNotices() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        Constants.myNoticesUrl,
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch notices';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        Constants.dashboardUrl,
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch dashboard';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getAllNotices() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        '${Constants.baseUrl}/superadmin/notices',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch notices';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        Constants.usersUrl,
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch users';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> addUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.post(
        Constants.addUserUrl,
        data: userData,
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to add user';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> postNotice(
    FormData formData,
  ) async {
    try {
      final token = await getToken();
      final response = await _dio.post(
        Constants.postNoticeUrl,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      final message = detail != null 
          ? detail.toString() 
          : 'Failed: ${e.message} (${e.response?.statusCode})';
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Client Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteNotice(int noticeId) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.delete(
        '${Constants.noticesUrl}/$noticeId',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to delete notice';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.put(
        '${Constants.baseUrl}/superadmin/user/$userId/toggle-status',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to update status';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.delete(
        '${Constants.baseUrl}/superadmin/user/$userId',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to delete user';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> deleteStudentsBatch(
      String year, String department) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.delete(
        '${Constants.baseUrl}/superadmin/students/batch',
        queryParameters: {'year': year, 'department': department},
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Failed to delete students';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> promoteStudents(
      String year, String department) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.put(
        '${Constants.baseUrl}/superadmin/students/promote',
        queryParameters: {'year': year, 'department': department},
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message =
          e.response?.data['detail'] ?? 'Failed to promote students';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getStudents(
      {String? year, String? department}) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        Constants.studentsUrl,
        queryParameters: {
          if (year != null) 'year': year,
          if (department != null) 'department': department,
        },
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch students';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> askChatbot(String query) async {
    try {
      final headers = await getHeaders();
      final response = await _dio.post(
        Constants.chatbotUrl,
        data: {'query': query},
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Chatbot is unavailable';
      return {'success': false, 'message': message};
    }
  }

  static Future<void> trackNoticeView(int noticeId) async {
    try {
      final headers = await getHeaders();
      await _dio.post(
        '${Constants.noticesUrl}/$noticeId/view',
        options: Options(headers: headers),
      );
    } catch (_) {
      // Silently ignore — tracking failure must not break UX
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        '${Constants.baseUrl}/analytics/stats',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch analytics';
      return {'success': false, 'message': message};
    }
  }

  static Future<Map<String, dynamic>> getUrgencyMap() async {
    try {
      final headers = await getHeaders();
      final response = await _dio.get(
        '${Constants.baseUrl}/notices/urgency-map',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Failed to fetch urgency map';
      return {'success': false, 'message': message};
    }
  }
}