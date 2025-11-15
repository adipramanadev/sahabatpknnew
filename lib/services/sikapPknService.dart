import 'dart:convert';
import 'package:http/http.dart' as http;

class SikapService {
  final String baseUrl;
  final String bearerToken;

  SikapService({
    required this.baseUrl,
    this.bearerToken = 'Xp8b8F8hpfPy6bxK24pjTwt6m',
  });

  /// Kirim data sikap ke server
  /// kembalikan body JSON dari server (Map) atau lempar Exception kalau gagal
  Future<Map<String, dynamic>> postSikap({
    required String endpoint,
    required Map<String, dynamic> payload,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse(_join(baseUrl, endpoint));
    final headers = <String, String>{
      'Authorization': 'Bearer $bearerToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'SahabatPKN/1.0 (Flutter)',
    };

    final resp = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(timeout);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        // Jika server tidak mengembalikan JSON valid, tetap kembalikan raw
        return {'statusCode': resp.statusCode, 'body': resp.body};
      }
    } else {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  String _join(String a, String b) {
    if (a.endsWith('/')) {
      return b.startsWith('/') ? (a + b.substring(1)) : (a + b);
    } else {
      return b.startsWith('/') ? (a + b) : ('$a/$b');
    }
  }
}
