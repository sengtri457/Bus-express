import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LlmApiService {
  static const _defaultUrl = 'https://cadmic-beverlee-merocrine.ngrok-free.dev/api/chat';
  static const _key = 'llm_api_url';

  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _defaultUrl;
  }

  static Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  static Future<String> sendMessage({
    required String message,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final apiUrl = baseUrl ?? await getApiUrl();
    final uri = Uri.parse(apiUrl);

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String? ?? '';
    }

    final detail = _extractDetail(response.body);
    throw LlmApiException(detail, response.statusCode);
  }

  static String _extractDetail(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Unknown error';
    } catch (_) {
      return body.isNotEmpty ? body : 'Connection failed';
    }
  }
}

class LlmApiException implements Exception {
  final String message;
  final int statusCode;

  const LlmApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
