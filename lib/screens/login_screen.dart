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
  static const _lineColor = Color(0xFFD9BFAE);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode(); // hanya untuk warna ikon/label saat fokus
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _hide = true;

  late final AnimationController _enter; // animasi masuk
  late final Animation<double> _logoA, _textA, _sheetA;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

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
    super.dispose();
  }

  double _c(double v) => v.clamp(0.0, 1.0).toDouble();

  // ---------- SISTEM LOGIN (tidak diubah) ----------

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  String _friendly(Object e) {
    if (e is FirebaseAuthException) {
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
    return 'Terjadi kesalahan: $e';
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.login(_email.text.trim(), _pass.text);
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
      _showError(_friendly(e));
    } catch (e) {
      _showError(_friendly(e));
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
              autocorrect: false,
              enableSuggestions: false,
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
    // controller TIDAK di-dispose di sini: dialog masih beranimasi menutup
    // dan memakainya, sehingga dispose langsung memicu error.
    final email = c.text.trim();
    if (ok != true) return;

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

  // ---------- DEKORASI INPUT (gaya garis bawah) ----------
  UnderlineInputBorder _line(Color c, [double w = 1.2]) => UnderlineInputBorder(
        borderSide: BorderSide(color: c, width: w),
      );

  InputDecoration _deco(String label, IconData icon, FocusNode? focus,
      {Widget? suffix}) {
    final focused = focus?.hasFocus ?? false;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: focused ? AppColors.bell : AppColors.muted),
      floatingLabelStyle:
          const TextStyle(color: AppColors.bell, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: focused ? AppColors.bell : AppColors.steel),
      suffixIcon: suffix,
      filled: false, // tanpa kotak
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: _line(_lineColor),
      enabledBorder: _line(_lineColor),
      focusedBorder: _line(AppColors.bell, 2),
      errorBorder: _line(AppColors.danger, 1.4),
      focusedErrorBorder: _line(AppColors.danger, 2),
    );
  }

  /// Tombol silang kecil untuk menghapus seluruh isi sebuah kolom.
  Widget _clearButton(TextEditingController c) => IconButton(
        tooltip: 'Hapus',
        splashRadius: 20,
        icon: const Icon(Icons.cancel_rounded, color: AppColors.muted, size: 20),
        onPressed: () {
          c.clear();
          setState(() {});
        },
      );

  // ---------- BAGIAN ATAS: logo kaca + judul ----------
  Widget _header() {
    final logo = _logoA.value;
    final text = _c(_textA.value);
    return Column(
      children: [
        Opacity(
          opacity: _c(logo),
          child: Transform.scale(
              scale: 0.6 + 0.4 * logo, child: const _GlassLogo()),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: text,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - text)),
            child: const Column(children: [
              Text('Inventaris Lab',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              SizedBox(height: 4),
              Text('Kelola alat dan bahan lab dengan mudah',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------- KARTU KACA: form ----------
  Widget _card() {
    final v = _sheetA.value;
    return Opacity(
      opacity: _c(v),
      child: Transform.translate(
        offset: Offset(0, 60 * (1 - v)),
        child: Column(
          children: [
            GlassCard(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EMAIL
                    TextFormField(
                      controller: _email,
                      focusNode: _emailFocus,
                      style: const TextStyle(color: AppColors.text, fontSize: 16),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _passFocus.requestFocus(),
                      decoration: _deco(
                        'Email',
                        Icons.mail_outline_rounded,
                        _emailFocus,
                        suffix:
                            _email.text.isEmpty ? null : _clearButton(_email),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // PASSWORD
                    TextFormField(
                      controller: _pass,
                      focusNode: _passFocus,
                      style: const TextStyle(color: AppColors.text, fontSize: 16),
                      obscureText: _hide,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _deco(
                        'Password',
                        Icons.lock_outline_rounded,
                        _passFocus,
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_pass.text.isNotEmpty) _clearButton(_pass),
                            IconButton(
                              tooltip: _hide
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
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
                          ],
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
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
                    const SizedBox(height: 4),

                    GradientButton(
                      text: 'Masuk',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun? ',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, cons) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: cons.maxHeight),
                child: AnimatedBuilder(
                  animation: _enter,
                  builder: (_, __) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _header(),
                      const SizedBox(height: 26),
                      _card(),
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
}

/// Logo kaca.
class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      radius: 28,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Icon(Icons.science, size: 40, color: AppColors.deep),
      ),
    );
  }
}