import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiClient {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  List<String> get _candidateUrls => [
        AppConstants.baseUrl,
        'http://127.0.0.1:8000/api',
        'http://10.133.242.102:8000/api',
      ];

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    Exception? lastException;

    for (final baseUrl in _candidateUrls) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        return _handleResponse(response);
      } on SocketException catch (e) {
        lastException = e;
      } on TimeoutException catch (e) {
        lastException = e;
      } catch (e) {
        rethrow;
      }
    }
    throw SocketException("Backend network timeout. Ensure phone & PC are on the same Wi-Fi network or backend is online.");
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    Exception? lastException;

    for (final baseUrl in _candidateUrls) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 5));

        return _handleResponse(response);
      } on SocketException catch (e) {
        lastException = e;
      } on TimeoutException catch (e) {
        lastException = e;
      } catch (e) {
        rethrow;
      }
    }
    throw SocketException("Backend network timeout. Ensure phone & PC are on the same Wi-Fi network or backend is online.");
  }

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final detail = body is Map && body.containsKey('detail')
          ? body['detail']
          : 'Server Error (${response.statusCode})';
      throw HttpException(detail.toString());
    }
  }
}
