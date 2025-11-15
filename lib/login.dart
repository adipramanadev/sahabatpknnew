import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahabatpknnew/blankPage.dart';
import 'package:sahabatpknnew/services/LoginService.dart';

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

  late final AnimationController _introCtrl;
  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<Position?> _ensureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showMsg('Location service dimatikan');
      return null;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      _showMsg('Izin lokasi ditolak');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _showMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _login() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Optional: Get location if needed
      final pos = await _ensureLocation();
      if (pos == null) {
        setState(() => _loading = false);
        return;
      }

      // Call LoginService
      final result = await _loginService.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showMsg(result['message'] ?? 'Login berhasil');

        // Navigate to home page
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, __, ___) => BlankPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        _showMsg(result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      if (mounted) {
        _showMsg('Login error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                      Text(
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
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                                    color: Colors.black.withValues(alpha: 0.04),
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
                                      if (v == null || v.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      if (v.length < 6) {
                                        return 'Minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
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
          color: const Color(0xffff5630).withValues(alpha: 153),
          width: 1.2,
        ),
      ),
    );
  }
}
