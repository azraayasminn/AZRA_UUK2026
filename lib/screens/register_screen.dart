import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'common.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kelas = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _name.text.trim(),
        'kelas': _kelas.text.trim(),
        'email': cred.user!.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Registrasi gagal')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _kelas.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool pass = false, TextInputType? type, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: pass,
        keyboardType: type,
        decoration:
            InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.bell)),
        validator:
            validator ?? (v) => (v == null || v.trim().isEmpty) ? '$hint wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Buat akun',
      subtitle: 'Daftar untuk meminjam alat lab',
      showBack: true,
      child: Form(
        key: _form,
        child: Column(children: [
          _field(_name, 'Nama', Icons.person_outline),
          _field(_kelas, 'Kelas', Icons.school_outlined),
          _field(_email, 'Email', Icons.mail_outline,
              type: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null),
          _field(_pass, 'Password', Icons.lock_outline,
              pass: true,
              validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null),
          const SizedBox(height: 12),
          GradientButton(
              text: 'Daftar', loading: _loading, onPressed: _loading ? null : _register),
        ]),
      ),
    );
  }
}