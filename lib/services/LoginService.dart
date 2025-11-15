import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
  static const String baseUrl = 'https://pkn.or.id/api';
  static const String bearerToken = 'Xp8b8F8hpfPy6bxK24pjTwt6m';

  /// Login dengan email dan password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth_login.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'User-Agent': 'SahabatPKN/1.0 (Flutter)',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'action': 'login',
        }),
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Cek berbagai format response yang mungkin
        if (data['status'] == true ||
            data['success'] == true ||
            data['token'] != null ||
            data['data']?['token'] != null) {
          // Extract token dari berbagai kemungkinan lokasi
          String? token =
              data['token'] ??
              data['access_token'] ??
              data['auth_token'] ??
              data['data']?['token'] ??
              data['data']?['access_token'];

          // Extract user data
          Map<String, dynamic>? userData =
              data['user'] ?? data['data']?['user'] ?? data['data'];

          if (token != null && token.isNotEmpty) {
            // Simpan token ke SharedPreferences
            await _saveToken(token);

            // Simpan user data jika ada
            if (userData != null) {
              await _saveUserData(userData);
            }

            print('✅ Login successful!');
            return {
              'success': true,
              'message': data['message'] ?? 'Login berhasil',
              'token': token,
              'user': userData,
            };
          } else {
            return {
              'success': false,
              'message': 'Token tidak ditemukan dalam response',
            };
          }
        } else {
          return {
            'success': false,
            'message':
                data['message'] ?? 'Login gagal. Email atau password salah.',
          };
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Email atau password salah'};
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Data yang dikirim tidak valid',
        };
      } else {
        return {
          'success': false,
          'message':
              'Gagal terhubung ke server. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Register user baru
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      print('📝 Attempting registration for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'User-Agent': 'SahabatPKN/1.0 (Flutter)',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'action': 'register',
        }),
      );

      print('📡 Register response status: ${response.statusCode}');
      print('📡 Register response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true || data['success'] == true) {
          // Extract token jika langsung login setelah register
          String? token = data['token'] ?? data['data']?['token'];

          if (token != null && token.isNotEmpty) {
            await _saveToken(token);
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Registrasi berhasil',
            'token': token,
            'user': data['user'] ?? data['data']?['user'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Registrasi gagal',
          };
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Data yang dikirim tidak valid',
          'errors': data['errors'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Gagal terhubung ke server. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Register error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();

      if (token != null) {
        // Optional: Call logout API endpoint
        try {
          await http.post(
            Uri.parse('$baseUrl/logout.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
        } catch (e) {
          print('⚠️ Logout API call failed: $e');
        }
      }

      // Clear local storage
      await clearSession();

      return {'success': true, 'message': 'Logout berhasil'};
    } catch (e) {
      print('❌ Logout error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan saat logout'};
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true || data['success'] == true) {
          return {'success': true, 'user': data['user'] ?? data['data']};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengambil data profile',
          };
        }
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Session expired. Silakan login kembali.',
        };
      } else {
        return {'success': false, 'message': 'Gagal terhubung ke server'};
      }
    } catch (e) {
      print('❌ Get profile error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Simpan token ke SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('💾 Token saved to storage');
  }

  /// Simpan user data ke SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
    print('💾 User data saved to storage');
  }

  /// Ambil token dari SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Ambil user data dari SharedPreferences
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear session (logout lokal)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    print('🗑️ Session cleared');
  }

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'action': 'forgot_password'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': data['status'] == true || data['success'] == true,
          'message': data['message'] ?? 'Email reset password telah dikirim',
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengirim email reset password',
        };
      }
    } catch (e) {
      print('❌ Forgot password error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Verify token validity
  Future<bool> verifyToken() async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/verify-token.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      } else if (response.statusCode == 401) {
        await clearSession();
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Verify token error: $e');
      return false;
    }
  }
}
