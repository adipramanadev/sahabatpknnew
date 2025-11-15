import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahabatpknnew/models/news.dart';

class ApiService {
  final String baseUrl;
  final String authToken;
  late final http.Client _httpClient;

  ApiService({
    this.baseUrl = 'https://pkn.or.id/api/',
    required this.authToken,
  }) {
    // Create a custom HTTP client that can handle SSL issues
    _httpClient = http.Client();
  }

  Map<String, String> get _headersJson => {
    'Authorization': 'Bearer $authToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'SahabatPKN/1.0 (Flutter)',
  };

  // === List News (POST) ===
  Future<List<News>> getNews(String token) async {
    try {
      final uri = Uri.parse('${baseUrl}news.php');
      
      // Exact headers that work with the API
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'SahabatPKN/1.0 (Flutter)',
      };
      
      print('🚀 POST Request: $uri');
      print('🔑 Bearer Token: $token');
      print('📋 Headers: $headers');
      
      final res = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode({}), // Empty JSON body as required
      ).timeout(const Duration(seconds: 30));

      print('📥 Response Status: ${res.statusCode}');
      print('📄 Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // Check if response has expected structure
        if (data['status'] == 'success' && data['data'] != null) {
          final List list = (data['data'] as List);
          print('✅ Successfully loaded ${list.length} news items');
          return list.map((e) => News.fromJson(e)).toList();
        } else {
          throw Exception('API response format tidak sesuai: ${data['status']}');
        }
      }
      
      if (res.statusCode == 401) {
        throw Exception('Token tidak valid atau expired. Coba restart aplikasi.');
      }
      
      throw Exception('API Error ${res.statusCode}: ${res.body}');
      
    } catch (e) {
      print('❌ Error in getNews: $e');
      
      // Only retry on network issues, not authentication errors
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        print('🔄 Network issue detected, retrying...');
        return _retryGetNews(token);
      }
      
      rethrow;
    }
  }
  
  // Retry method for network issues
  Future<List<News>> _retryGetNews(String token) async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Brief delay before retry
      
      final uri = Uri.parse('${baseUrl}news.php');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      print('🔄 Retrying POST request...');
      
      final res = await _httpClient.post(
        uri,
        headers: headers,
        body: '{}',
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List list = (data['data'] as List);
          print('✅ Retry successful: ${list.length} news items');
          return list.map((e) => News.fromJson(e)).toList();
        }
      }
      
      throw Exception('Retry failed: ${res.statusCode}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
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

        final res = await _httpClient
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

  void dispose() {
    _httpClient.close();
  }
}
