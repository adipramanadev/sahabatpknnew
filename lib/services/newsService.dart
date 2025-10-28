import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahabatpknnew/models/news.dart';

class ApiService {
  final String baseUrl;
  final String authToken;

  ApiService({
    this.baseUrl = 'https://pkn.or.id/api/',
    required this.authToken,
  });

  Map<String, String> get _headersJson => {
    'Authorization': 'Bearer $authToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'SahabatPKN/1.0 (Flutter)',
  };

  // === List News (POST) ===
  Future<List<News>> getNews(String token) async {
    final uri = Uri.parse('${baseUrl}news.php');
    final res = await http
        .post(uri, headers: _headersJson, body: jsonEncode({}))
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List list = (data['data'] ?? []) as List;
      return list.map((e) => News.fromJson(e)).toList();
    }
    if (res.statusCode == 401) {
      throw Exception(
        '401 Unauthorized: token invalid/expired untuk list news.',
      );
    }
    throw Exception('Gagal ambil berita: ${res.statusCode} ${res.body}');
  }

  // === Detail News (GET) ===
  Future<News> getNewsDetail(String key) async {
    final isNumericId = RegExp(r'^\d+$').hasMatch(key);
    
    // Try different parameter names based on API requirements
    List<String> paramNames = isNumericId 
        ? ['id', 'ID'] 
        : ['slug', 'seo_url'];
    
    Exception? lastException;
    
    for (String qParam in paramNames) {
      try {
        final value = Uri.encodeQueryComponent(key);
        final uri = Uri.parse('${baseUrl}newsDetail?$qParam=$value');

        final res = await http
            .get(uri, headers: _headersJson)
            .timeout(const Duration(seconds: 20));

        print('➡️ Request: $uri');
        print('➡️ Header: $_headersJson');
        print('⬅️ Status: ${res.statusCode}');
        print('⬅️ Body: ${res.body}');

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final dynamic raw = body['data'] ?? body;
          if (raw is Map<String, dynamic>) {
            return News.fromJson(raw);
          }
          throw Exception('Struktur detail tidak dikenali.');
        }

        if (res.statusCode == 401) {
          throw Exception(
            '401 Unauthorized: pastikan Bearer token dikirim dan benar.',
          );
        }
        
        if (res.statusCode == 400) {
          // Try next parameter name for 400 Bad Request
          lastException = Exception('400 Bad Request: parameter $qParam tidak diterima API');
          continue;
        }
        
        if (res.statusCode == 404) {
          lastException = Exception(
            '404 Not Found: artikel tidak ditemukan untuk $qParam=$key',
          );
          continue;
        }
        
        lastException = Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        // Try next parameter name
        continue;
      }
    }
    
    // If all attempts failed, throw the last exception
    throw lastException ?? Exception('Gagal memuat detail berita dengan semua parameter');
  }
}
