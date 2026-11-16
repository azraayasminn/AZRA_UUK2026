import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const _headerH = 250.0;

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _hide = true;
  String? _error;

  late final AnimationController _enter; // animasi masuk
  late final AnimationController _float; // lingkaran cahaya
  late final AnimationController _shake; // getar saat salah
  late final Animation<double> _logoA, _textA, _sheetA;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _logoA = CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    _textA = CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut));
    _sheetA = CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic));

    _emailFocus.addListener(_refresh);
    _passFocus.addListener(_refresh);
    _enter.forward();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _enter.dispose();
    _float.dispose();
    _shake.dispose();
    super.dispose();
  }

  double _c(double v) => v.clamp(0.0, 1.0).toDouble();

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return e.message ?? 'Login gagal.';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) {
      _shake.forward(from: 0);
      return;
    }
    setState(() => _loading = true);
    try {
      await FirestoreService.login(_email.text, _pass.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendly(e));
      _shake.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Terjadi kesalahan: $e');
      _shake.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final c = TextEditingController(text: _email.text.trim());
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Lupa password?',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Masukkan emailmu. Kami kirim tautan untuk mengatur ulang password.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              keyboardType: TextInputType.emailAddress,
              decoration: _deco('Email', Icons.mail_outline_rounded, null),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kirim',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok != true) return;

    final email = c.text.trim();
    if (!email.contains('@')) {
      messenger.showSnackBar(const SnackBar(content: Text('Email tidak valid')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
          SnackBar(content: Text('Tautan reset dikirim ke $email')));
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'user-not-found'
          ? 'Email belum terdaftar.'
          : _friendly(e);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------- DEKORASI INPUT ----------
  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  InputDecoration _deco(String label, IconData icon, FocusNode? focus,
      {Widget? suffix}) {
    final focused = focus?.hasFocus ?? false;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: focused ? AppColors.bell : AppColors.muted),
      floatingLabelStyle: const TextStyle(
          color: AppColors.bell, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: focused ? AppColors.bell : AppColors.sky),
      suffixIcon: suffix,
      filled: true,
      fillColor: focused ? Colors.white : AppColors.alice,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: _border(Colors.transparent),
      enabledBorder: _border(Colors.transparent),
      focusedBorder: _border(AppColors.bell, 1.8),
      errorBorder: _border(AppColors.danger, 1.2),
      focusedErrorBorder: _border(AppColors.danger, 1.8),
    );
  }

  Widget _glow(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(0),
          ]),
        ),
      );

  // ---------- BAGIAN ATAS ----------
  Widget _header() {
    final logo = _logoA.value;
    final text = _c(_textA.value);
    return SizedBox(
      height: _headerH,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: _c(logo),
            child: Transform.scale(
                scale: 0.6 + 0.4 * logo, child: const _GlassLogo()),
          ),
          const SizedBox(height: 18),
          Opacity(
            opacity: text,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - text)),
              child: const Column(children: [
                Text('Selamat datang',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Masuk untuk melanjutkan',
                    style: TextStyle(color: AppColors.alice, fontSize: 14)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- KARTU PUTIH ----------
  Widget _sheet(double minH) {
    final v = _sheetA.value;
    return Opacity(
      opacity: _c(v),
      child: Transform.translate(
        offset: Offset(0, 70 * (1 - v)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minH),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masuk ke akunmu',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                  const SizedBox(height: 4),
                  const Text('Gunakan email dan password yang terdaftar',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 24),

                  // kolom input (bergetar saat salah)
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (_, child) {
                      final t = _shake.value;
                      final dx = math.sin(t * math.pi * 5) * 10 * (1 - t);
                      return Transform.translate(
                          offset: Offset(dx, 0), child: child);
                    },
                    child: Column(children: [
                      TextFormField(
                        controller: _email,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) => _clearError(),
                        onFieldSubmitted: (_) => _passFocus.requestFocus(),
                        decoration: _deco(
                            'Email', Icons.mail_outline_rounded, _emailFocus),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(s)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pass,
                        focusNode: _passFocus,
                        obscureText: _hide,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onChanged: (_) => _clearError(),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _deco(
                          'Password',
                          Icons.lock_outline_rounded,
                          _passFocus,
                          suffix: IconButton(
                            splashRadius: 20,
                            onPressed: () => setState(() => _hide = !_hide),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (c, a) =>
                                  ScaleTransition(scale: a, child: c),
                              child: Icon(
                                _hide
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                key: ValueKey(_hide),
                                color: AppColors.steel,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (v.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                    ]),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _forgot,
                      child: const Text('Lupa password?',
                          style: TextStyle(
                              color: AppColors.bell,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),

                  // banner error
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.danger.withOpacity(.4)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ),
                  ),

                  GradientButton(
                    text: 'Login',
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? ',
                          style:
                              TextStyle(fontSize: 13, color: AppColors.muted)),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text('Daftar',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.bell,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: headerGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // lingkaran cahaya yang bergerak pelan
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, __) {
                  final dy = (_float.value - .5) * 30;
                  return Stack(children: [
                    Positioned(top: -70 + dy, right: -60, child: _glow(250, .30)),
                    Positioned(top: 140 - dy, left: -90, child: _glow(210, .20)),
                  ]);
                },
              ),
            ),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, cons) {
                  final sheetMin = math.max(0.0, cons.maxHeight - _headerH);
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: AnimatedBuilder(
                      animation: _enter,
                      builder: (_, __) => Column(children: [
                        _header(),
                        _sheet(sheetMin),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo kaca, gayanya sama dengan splash screen.
class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (r) => headerGradient.createShader(r),
              child: const Icon(Icons.science, size: 38, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}