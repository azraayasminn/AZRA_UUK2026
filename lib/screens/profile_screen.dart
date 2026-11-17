
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'history_screen.dart';
import 'login_screen.dart';

const _logoutRed = Color(0xFFB83B3B);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _editProfile(
    BuildContext context,
    Map<String, dynamic> u,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: u),
    );
  }

  // ================= KONFIRMASI LOGOUT =================

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Yakin ingin keluar?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin logout dari akun ini?',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(
                color: _logoutRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await FirestoreService.logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  // ================= STATISTIK =================



  // ================= MENU TILE =================

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: glassDecoration(radius: 22, opacity: .55),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
            ),
            onTap: onTap,
          ),
        ),
      );

  // ================= TOMBOL LOGOUT =================

  Widget _logoutButton(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _confirmLogout(context),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _logoutRed.withOpacity(.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _logoutRed.withOpacity(.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _logoutRed.withOpacity(.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: _logoutRed,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Logout',
                  style: TextStyle(
                    color: _logoutRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ================= HEADER =================

  Widget _header(
    BuildContext context,
    Map<String, dynamic> u,
    ImageProvider? provider,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        8,
      ),
      child: Column(
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _editProfile(context, u),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: headerGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deep.withOpacity(.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.pale,
                      backgroundImage: provider,
                      onBackgroundImageError:
                          provider == null ? null : (_, __) {},
                      child: provider == null
                          ? const Icon(
                              Icons.person,
                              size: 52,
                              color: AppColors.deep,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            u['name'] ?? '-',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            u['email'] ?? '',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            decoration: glassDecoration(
              radius: 20,
              opacity: .6,
            ),
            child: Text(
              'Kelas ${u['kelas'] ?? '-'}',
              style: const TextStyle(
                color: AppColors.deep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<Map<String, dynamic>>(
          stream: FirestoreService.streamUser(),
          builder: (context, snap) {
            if (!FirestoreService.loggedIn) {
              return const SizedBox.shrink();
            }

            final u = snap.data ?? {};
            final foto = (u['foto'] ?? '').toString();
            final provider = photoProvider(foto);

            // Cek role akun
            final isAdmin = u['role'] == 'admin';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(context, u, provider),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 28,
                  ),
                  child: Column(
                    children: [

                      // ================= EDIT PROFIL =================

                      _menuTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profil',
                        subtitle: 'Ubah nama, kelas, dan foto',
                        onTap: () => _editProfile(context, u),
                      ),

                      // ================= RIWAYAT =================
                      // HANYA DITAMPILKAN UNTUK USER

                      if (!isAdmin)
                        _menuTile(
                          icon: Icons.history,
                          title: 'Riwayat Peminjaman',
                          subtitle:
                              'Pinjam, kembalikan, dan lihat riwayat',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const HistoryScreen(),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // ================= LOGOUT =================

                      _logoutButton(context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================
// FORM EDIT PROFIL
// =============================================================

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();

  late final String _orig =
      (widget.user['foto'] ?? '').toString();

  late final bool _legacy = _orig.startsWith('data:');

  late final _name = TextEditingController(
    text: (widget.user['name'] ?? '').toString(),
  );

  late final _kelas = TextEditingController(
    text: (widget.user['kelas'] ?? '').toString(),
  );

  late final _foto = TextEditingController(
    text: _legacy ? '' : _orig,
  );

  bool _cleared = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _kelas.dispose();
    _foto.dispose();
    super.dispose();
  }

  String get _fotoToSave {
    final typed = _foto.text.trim();

    if (typed.isEmpty && _legacy && !_cleared) {
      return _orig;
    }

    return typed;
  }

  // ================= SIMPAN PROFIL =================

  Future<void> _save() async {
    if (_saving) return;

    if (!_form.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _saving = true);

    try {
      await FirestoreService.updateProfile(
        name: _name.text,
        kelas: _kelas.text,
        foto: _fotoToSave,
      );

      if (!mounted) return;

      nav.pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil diperbarui'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
        ),
      );

      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ================= INPUT DECORATION =================

  UnderlineInputBorder _line(
    Color c, [
    double w = 1.2,
  ]) =>
      UnderlineInputBorder(
        borderSide: BorderSide(
          color: c,
          width: w,
        ),
      );

  InputDecoration _deco(
    String label,
    IconData icon, {
    String? hint,
    String? helper,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      labelStyle: const TextStyle(
        color: AppColors.muted,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.bell,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.bell,
      ),
      suffixIcon: suffix,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      border: _line(AppColors.pale),
      enabledBorder: _line(AppColors.pale),
      focusedBorder: _line(AppColors.bell, 2),
      errorBorder: _line(AppColors.danger, 1.4),
      focusedErrorBorder: _line(AppColors.danger, 2),
    );
  }

  // ================= PREVIEW FOTO =================

  Widget _preview() {
    final provider = photoProvider(_fotoToSave);

    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.pale,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deep.withOpacity(.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: provider == null
              ? const Icon(
                  Icons.person,
                  size: 48,
                  color: AppColors.deep,
                )
              : Image(
                  image: provider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(
                    Icons.broken_image_outlined,
                    size: 36,
                    color: AppColors.muted,
                  ),
                ),
        ),
      ),
    );
  }

  // ================= BUILD FORM =================

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(32),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              22, 12, 22, 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.88),
              borderRadius: radius,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(.9),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.pale,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _preview(),

                      const SizedBox(height: 12),

                      // Nama
                      TextFormField(
                        controller: _name,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: _deco(
                          'Nama',
                          Icons.person_outline,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                      ),

                      const SizedBox(height: 10),

                      // Kelas
                      TextFormField(
                        controller: _kelas,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: _deco(
                          'Kelas',
                          Icons.school_outlined,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Kelas wajib diisi'
                                : null,
                      ),

                      const SizedBox(height: 10),

                      // URL Foto
                      TextFormField(
                        controller: _foto,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (_) {
                          setState(() => _cleared = false);
                        },
                        decoration: _deco(
                          'URL Foto',
                          Icons.link,
                          hint: 'https://...',
                          helper: _legacy &&
                                  !_cleared &&
                                  _foto.text.trim().isEmpty
                              ? 'Foto saat ini hasil upload lama. Isi URL untuk menggantinya.'
                              : 'Tempel link gambar. Kosongkan untuk menghapus foto.',
                          suffix: (_foto.text.isEmpty &&
                                  !(_legacy && !_cleared))
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus foto',
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _foto.clear();
                                      _cleared = true;
                                    });
                                  },
                                ),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();

                          if (t.isEmpty) return null;

                          if (!t.startsWith('http://') &&
                              !t.startsWith('https://')) {
                            return 'URL harus diawali http:// atau https://';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      GradientButton(
                        text: 'Simpan',
                        loading: _saving,
                        onPressed: _saving ? null : _save,
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
}
