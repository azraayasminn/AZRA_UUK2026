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

  String _role = 'user';
  bool _loading = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'user_id': cred.user!.uid,
        'name': _name.text.trim(),
        'kelas': _kelas.text.trim(),
        'email': cred.user!.email,
        'role': _role,
        'foto': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _role == 'admin'
                ? 'Registrasi Admin berhasil!'
                : 'Registrasi User berhasil!',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Registrasi gagal'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool pass = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: pass,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: AppColors.bell,
          ),
        ),
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) {
                return '$hint wajib diisi';
              }
              return null;
            },
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
        child: Column(
          children: [
            _field(
              _name,
              'Nama',
              Icons.person_outline,
            ),

            _field(
              _kelas,
              'Kelas',
              Icons.school_outlined,
            ),

            _field(
              _email,
              'Email',
              Icons.mail_outline,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                  return 'Email tidak valid';
                }
                return null;
              },
            ),

            _field(
              _pass,
              'Password',
              Icons.lock_outline,
              pass: true,
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'Minimal 6 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar sebagai',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.bell.withOpacity(0.4),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 10),
                          Text('User'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined),
                          SizedBox(width: 10),
                          Text('Admin'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _role = value);
                          }
                        },
                ),
              ),
            ),

            const SizedBox(height: 20),

            GradientButton(
              text: 'Daftar',
              loading: _loading,
              onPressed: _loading ? null : _register,
            ),
          ],
        ),
      ),
    );
  }
}