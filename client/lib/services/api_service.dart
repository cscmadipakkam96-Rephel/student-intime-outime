import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show navigatorKey;

// Android/iOS have no automatic browser cookie jar like Chrome does, so we
// capture the Set-Cookie header ourselves after login and resend it as the
// Cookie header on every later request. Stored in SharedPreferences so the
// session survives an app restart too.
class ApiService {
  static const String baseUrl = 'https://app.cscitedu.com';
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

  // Every authenticated call should route its response through here — it's
  // what catches the backend's single-active-device signal (a newer login
  // elsewhere invalidated this device's session) and forces the app back
  // to the login screen instead of leaving every screen to fail silently
  // with a confusing "not authenticated" error one at a time.
  static Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] == 'SESSION_INVALIDATED') {
      await _handleSessionInvalidated();
    }
    return {'statusCode': response.statusCode, ...data};
  }

  static bool _handlingSessionInvalidated = false;

  static Future<void> _handleSessionInvalidated() async {
    if (_handlingSessionInvalidated) return;
    _handlingSessionInvalidated = true;
    try {
      await _clearCookie();
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      // The app's root route is already WelcomePage — popping back to it
      // avoids needing to import that page here (which would otherwise
      // create a circular import, since welcome_page.dart imports this file).
      navigator.popUntil((route) => route.isFirst);
      final context = navigator.context;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account was logged in on another device.')),
      );
    } finally {
      _handlingSessionInvalidated = false;
    }
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
    return _processResponse(response);
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
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> markOutTime() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/out'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/attendance/history'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getMyRecordings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/videos/recordings'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getCourseVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/course-videos'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getCourseVideoPlayUrl(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/course-videos/$id/play'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getBatches() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/student-app/batches'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getClassAttendance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/student-app/attendance'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> submitLeaveRequest({
    required int batchId,
    required String sessionDate,
    required String description,
    required String leaveType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/student-app/leave-requests'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'batch_id': batchId,
        'session_date': sessionDate,
        'description': description,
        'leave_type': leaveType,
      }),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> getLeaveRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/student-app/leave-requests'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> registerFcmToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/register-token'),
      headers: await _headers(json: true),
      body: jsonEncode({'fcm_token': token}),
    );
    return _processResponse(response);
  }

  // New backend has no server-triggered push — the app polls this for
  // undelivered notifications instead (see NotificationPollingService).
  static Future<Map<String, dynamic>> getPendingNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/student-app/notifications'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> ackNotification(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/student-app/notifications/ack?id=$id'),
      headers: await _headers(),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> ackNotificationsBulk(List<int> ids) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/student-app/notifications/ack-bulk'),
      headers: await _headers(json: true),
      body: jsonEncode({'ids': ids}),
    );
    return _processResponse(response);
  }

  // No auth header needed — checked before a session can even exist.
  static Future<Map<String, dynamic>> getMinAppVersion() async {
    final response = await http.get(Uri.parse('$baseUrl/api/app-version'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'statusCode': response.statusCode, ...data};
  }
}
