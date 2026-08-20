import 'dart:convert';
import 'package:http/browser_client.dart';

class ApiService {
  // While testing with `flutter run -d chrome`, the browser IS the cookie
  // store. BrowserClient's withCredentials makes it send/receive the
  // httpOnly JWT cookie automatically — no manual token storage needed.
  static const String baseUrl = 'http://localhost:5000';

  static final BrowserClient _client = BrowserClient()..withCredentials = true;

  static Future<Map<String, dynamic>> login({
    required String comnEnrolNo,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'comn_enrol_no': comnEnrolNo,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> me() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/auth/me'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await _client.post(Uri.parse('$baseUrl/api/auth/logout'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> markInTime() async {
    final response = await _client.post(Uri.parse('$baseUrl/api/attendance/in'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> markOutTime() async {
    final response = await _client.post(Uri.parse('$baseUrl/api/attendance/out'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<Map<String, dynamic>> getHistory() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/attendance/history'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }
}
