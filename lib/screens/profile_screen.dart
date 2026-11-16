import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _editProfile(BuildContext context, Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: u),
    );
  }

  Widget _stat(String label, int n) => Expanded(
        child: Column(children: [
          Text('$n',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deep)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      );

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: softShadow),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                gradient: headerGradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: FirestoreService.streamUser(),
        builder: (context, snap) {
          // setelah logout, jangan bangun apa pun (mencegah layar merah)
          if (!FirestoreService.loggedIn) return const SizedBox.shrink();
          final u = snap.data ?? {};
          final foto = (u['foto'] ?? '').toString();
          final provider = photoProvider(foto);
          return ListView(padding: EdgeInsets.zero, children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: headerGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(children: [
                const Text('Profil',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => _editProfile(context, u),
                  child: Stack(children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration:
                          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.pale,
                        backgroundImage: provider,
                        // URL rusak: tampilkan lingkaran kosong, bukan error
                        onBackgroundImageError:
                            provider == null ? null : (_, __) {},
                        child: provider == null
                            ? const Icon(Icons.person, size: 52, color: AppColors.deep)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bell,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Text(u['name'] ?? '-',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(u['email'] ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Kelas ${u['kelas'] ?? '-'}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // statistik peminjaman
                StreamBuilder<List<Borrowing>>(
                  stream: FirestoreService.streamBorrowings(),
                  builder: (context, s) {
                    if (!FirestoreService.loggedIn) return const SizedBox.shrink();
                    final list = s.data ?? [];
                    final aktif = list.where((b) => b.active).length;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: softShadow),
                      child: Row(children: [
                        _stat('Sedang Dipinjam', aktif),
                        _stat('Dikembalikan', list.length - aktif),
                        _stat('Total Pinjam', list.length),
                      ]),
                    );
                  },
                ),
                _menuTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama, kelas, dan foto',
                  onTap: () => _editProfile(context, u),
                ),
                _menuTile(
                  icon: Icons.history,
                  title: 'Riwayat Peminjaman',
                  subtitle: 'Pinjam, kembalikan, dan lihat riwayat',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.5),
                      backgroundColor: Colors.white,
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false);
                    },
                  ),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

// =====================================================================
// FORM EDIT PROFIL (bottom sheet)
// =====================================================================
class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final String _orig = (widget.user['foto'] ?? '').toString();
  // foto lama hasil upload galeri (base64): tetap dipertahankan kalau tidak diganti
  late final bool _legacy = _orig.startsWith('data:');
  late final _name =
      TextEditingController(text: (widget.user['name'] ?? '').toString());
  late final _kelas =
      TextEditingController(text: (widget.user['kelas'] ?? '').toString());
  late final _foto = TextEditingController(text: _legacy ? '' : _orig);
  bool _cleared = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _kelas.dispose();
    _foto.dispose();
    super.dispose();
  }

  /// URL yang akan disimpan.
  String get _fotoToSave {
    final typed = _foto.text.trim();
    if (typed.isEmpty && _legacy && !_cleared) return _orig;
    return typed;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await FirestoreService.updateProfile(
          name: _name.text, kelas: _kelas.text, foto: _fotoToSave);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview() {
    final provider = photoProvider(_fotoToSave);
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.pale,
          border: Border.all(color: AppColors.alice, width: 3),
        ),
        child: ClipOval(
          child: provider == null
              ? const Icon(Icons.person, size: 48, color: AppColors.deep)
              : Image(
                  image: provider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: AppColors.muted),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // naik mengikuti keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.pale, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 14),
                const Text('Edit Profil',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 16),
                _preview(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.bell)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _kelas,
                  decoration: const InputDecoration(
                      labelText: 'Kelas',
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.bell)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Kelas wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _foto,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() => _cleared = false),
                  decoration: InputDecoration(
                    labelText: 'URL Foto',
                    hintText: 'https://...',
                    helperText: _legacy && !_cleared && _foto.text.trim().isEmpty
                        ? 'Foto saat ini hasil upload lama. Isi URL untuk menggantinya.'
                        : 'Tempel link gambar. Kosongkan untuk menghapus foto.',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.link, color: AppColors.bell),
                    suffixIcon: (_foto.text.isEmpty && !(_legacy && !_cleared))
                        ? null
                        : IconButton(
                            tooltip: 'Hapus foto',
                            icon: const Icon(Icons.close, color: AppColors.muted),
                            onPressed: () => setState(() {
                              _foto.clear();
                              _cleared = true;
                            }),
                          ),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    if (!t.startsWith('http://') && !t.startsWith('https://')) {
                      return 'URL harus diawali http:// atau https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GradientButton(
                    text: 'Simpan', loading: _saving, onPressed: _saving ? null : _save),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}