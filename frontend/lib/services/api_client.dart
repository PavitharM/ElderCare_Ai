import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  String? get token => _authToken;

  Map<String, String> _buildHeaders() {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (_authToken != null) {
      headers["Authorization"] = "Bearer $_authToken";
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    return await http
        .get(url, headers: _buildHeaders())
        .timeout(ApiConfig.timeoutDuration);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    return await http
        .post(
          url,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.timeoutDuration);
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    return await http
        .put(
          url,
          headers: _buildHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.timeoutDuration);
  }
}
