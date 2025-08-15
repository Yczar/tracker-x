import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String? token;
  ApiClient(this.baseUrl, {this.token});

  Future<void> postLocation(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/locations'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> sendLocation({
    required double lat,
    required double lng,
    String? trackerId,
    double? accuracy,
    double? speed,
    DateTime? timestamp,
  }) async {
    final uri = Uri.parse('$baseUrl/locations');
    final body = jsonEncode({
      'trackerId': trackerId ?? 'flutter-client',
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': (timestamp ?? DateTime.now().toUtc()).toIso8601String(),
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to send location: ${res.statusCode}');
    }
  }
}
