import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sahabatpknnew/blankPage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _introCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _introCtrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<String?> _getApiKey() async {
    // Urutan prioritas:
    // 1) prefs (kalau sudah pernah diset)
    // 2) dart-define (flutter run --dart-define=API_KEY=xxx)
    // 3) null => suruh user set dulu
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_key_bearer');
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();

    const fromEnv = String.fromEnvironment('API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;

    return null;
  }

  // cari token di beberapa kemungkinan key
  String? _extractToken(Map<String, dynamic> jsonResp) {
    // root level
    final rootToken =
        (jsonResp['token'] ??
                jsonResp['access_token'] ??
                jsonResp['auth_token'])
            ?.toString();
    if (rootToken != null && rootToken.isNotEmpty) return rootToken;

    // di dalam data
    final data = jsonResp['data'];
    if (data is Map) {
      final t =
          (data['token'] ??
                  data['access_token'] ??
                  data['auth_token'] ??
                  data['token_bearer'] ??
                  data['api_key']) // kalau backend menaruhnya di sini
              ?.toString();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  Future<void> _login() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    void showMsg(String m) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));

    try {
      // Cek izin lokasi singkat (seperti kode kamu)
      if (!await Geolocator.isLocationServiceEnabled()) {
        showMsg('Location service dimatikan');
        setState(() => _loading = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        showMsg('Izin lokasi ditolak');
        setState(() => _loading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // final url = Uri.parse('https://sys.pkn.or.id/api/mobile/auth_login');
      final url = Uri.parse(
        'https://pkn.or.id/api/auth_login.php',
      ); 

      // === MIRROR POSTMAN: form-data + header Bearer ===
      final req = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer Xp8b8F8hpfPy6bxK24pjTwt6m'
        ..headers['Accept'] = 'application/json'
        ..fields['keylogin'] = _email.text.trim()
        ..fields['password'] = _password.text
        ..fields['lat'] = pos.latitude.toString()
        ..fields['long'] = pos.longitude.toString();

      final streamed = await req.send();
      final respBody = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        showMsg('Server error: ${streamed.statusCode}');
        // debugPrint(respBody);
        setState(() => _loading = false);
        return;
      }

      final jsonResp = jsonDecode(respBody) as Map<String, dynamic>;
      if ((jsonResp['status'] ?? '').toString().toLowerCase() != 'success') {
        showMsg(jsonResp['message']?.toString() ?? 'Login gagal');
        setState(() => _loading = false);
        return;
      }

      // Tidak ada token di respons — simpan profil & API key untuk request berikutnya
      final data = (jsonResp['data'] as Map?) ?? {};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', (data['username'] ?? '').toString());
      await prefs.setString('email', (data['email'] ?? '').toString());
      await prefs.setString('no_ktp', (data['no_ktp'] ?? '').toString());
      await prefs.setString('kaderID', (data['kaderID'] ?? '').toString());
      await prefs.setString('status', (data['status'] ?? '').toString());
      await prefs.setString('api_key_bearer', 'Xp8b8F8hpfPy6bxK24pjTwt6m');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => BlankPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      showMsg('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _introCtrl,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _introCtrl,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Masuk untuk melanjutkan",
                        style: TextStyle(
                          color: Colors.black.withOpacity(.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card form dengan animasi halus saat loading
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xfff7f7f8),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _loading
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: AbsorbPointer(
                          absorbing: _loading,
                          child: Opacity(
                            opacity: _loading ? 0.6 : 1,
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      hint: "Email",
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      final ok = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      ).hasMatch(v.trim());
                                      return ok
                                          ? null
                                          : 'Format email tidak valid';
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Password
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    decoration: _inputDecoration(
                                      hint: "Password",
                                      icon: Icons.lock_outline,
                                      trailing: IconButton(
                                        tooltip: _obscure
                                            ? 'Tampilkan'
                                            : 'Sembunyikan',
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password wajib diisi';
                                      if (v.length < 6)
                                        return 'Minimal 6 karakter';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Tombol Login dengan AnimatedSwitcher
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xffff5630,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: _loading
                                            ? const SizedBox(
                                                key: ValueKey('loader'),
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.6,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                key: ValueKey('label'),
                                                "Login",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Link Sign Up
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Belum punya akun?",
                              style: TextStyle(fontSize: 14),
                            ),
                            TextButton(
                              onPressed: _loading ? null : () {},
                              child: const Text(
                                "Daftar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xffff5630),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: trailing,
      filled: true,
      fillColor: const Color(0xfff2f2f3),
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xff9f9d9d)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xffff5630).withOpacity(.6),
          width: 1.2,
        ),
      ),
    );
  }
}
