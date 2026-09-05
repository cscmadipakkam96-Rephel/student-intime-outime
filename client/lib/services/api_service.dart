import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Android/iOS have no automatic browser cookie jar like Chrome does, so we
// capture the Set-Cookie header ourselves after login and resend it as the
// Cookie header on every later request. Stored in SharedPreferences so the
// session survives an app restart too.
class ApiService {
  static const String baseUrl = 'https://13-62-125-222.sslip.io';
  static const String _cookieKey = 'session_cookie';

  static Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  static Future<void> _saveCookieFrom(http.Response response) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final cookie = setCookie.split(';').first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookie);
  }

  static Future<void> _clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final cookie = await _getCookie();
    return {
      if (json) 'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    };
  }

  static Future<Map<String, dynamic>> login({
    required String comnEnrolNo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'comn_enrol_no': comnEnrolNo,
        'password': password,
      }),
    );

    await _saveCookieFrom(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: await _headers(),
    );
    await _clearCookie();
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> markInTime() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/in'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> markOutTime() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/out'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> getHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/attendance/history'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> getMyRecordings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/videos/recordings'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> getCourseVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/course-videos'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> getCourseVideoPlayUrl(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/course-videos/$id/play'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  // No auth header needed — checked before a session can even exist.
  static Future<Map<String, dynamic>> getMinAppVersion() async {
    final response = await http.get(Uri.parse('$baseUrl/api/app-version'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }
}
