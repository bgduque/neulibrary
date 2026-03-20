import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // In production, this is set via --dart-define=API_URL=...
  static const _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  String? _token;

  /// Store the JWT after authentication.
  void setToken(String? token) => _token = token;

  /// The current JWT token.
  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// POST /api/auth/google — exchange Google token for app JWT.
  /// Sends whichever token is available: [idToken] (mobile) or [accessToken] (web).
  Future<Map<String, dynamic>> authenticateWithGoogle({String? idToken, String? accessToken}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /api/users/me — fetch current user profile.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/users/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PUT /api/users/me/setup — complete onboarding.
  Future<Map<String, dynamic>> completeSetup(String collegeOffice) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/users/me/setup'),
      headers: _headers,
      body: jsonEncode({'collegeOffice': collegeOffice}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// POST /api/visits — check in.
  Future<void> checkIn(String reason) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/visits'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// GET /api/admin/stats?from=...&to=...
  Future<Map<String, dynamic>> getStats(String from, String to) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/stats?from=$from&to=$to'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/users?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PUT /api/admin/users/{userId}/block
  Future<Map<String, dynamic>> setBlocked(String userId, bool blocked) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/admin/users/$userId/block'),
      headers: _headers,
      body: jsonEncode({'blocked': blocked}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// GET /api/admin/visits?from=...&to=...
  Future<List<dynamic>> searchVisits(String from, String to) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/visits?from=$from&to=$to'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// PUT /api/admin/users/{userId}/role
  Future<Map<String, dynamic>> setRole(String userId, String role) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/admin/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// DELETE /api/admin/users/{userId}
  Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/admin/users/$userId'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  void clear() {
    _token = null;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
