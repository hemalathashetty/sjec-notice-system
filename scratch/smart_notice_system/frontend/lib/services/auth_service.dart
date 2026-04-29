import 'api_service.dart';
import '../utils/constants.dart';


class AuthService {
  // ─── LOGIN AND SAVE TOKEN ─────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final result = await ApiService.login(email, password);

    if (result['success']) {
      final data = result['data'];
      await ApiService.saveToken(data['access_token']);
      await ApiService.saveUserInfo(
        data['role'],
        data['full_name'],
      );
      await ApiService.saveUserId(data['user_id'] ?? 0);
      return {
        'success': true,
        'role': data['role'],
        'full_name': data['full_name'],
      };
    }
    return result;
  }

  // ─── LOGOUT ───────────────────────────────────────────────
  static Future<void> logout() async {
    await ApiService.clearStorage();
  }

  // ─── CHECK IF LOGGED IN ───────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  // ─── GET REDIRECT ROUTE BASED ON ROLE ────────────────────
  static String getRouteForRole(String role) {
    switch (role) {
      case Constants.roleSuperAdmin:
        return '/superadmin';
      case Constants.roleAdmin:
      case Constants.roleHod:
      case Constants.rolePlacement:
      case Constants.roleClub:
      case Constants.roleSports:
        return '/admin';
      case Constants.roleStudent:
        return '/student';
      default:
        return '/login';
    }
  }
}