
import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'net_image.dart';

/// Dipanggil dari Beranda untuk menampilkan detail alat.
void showItemSheet(BuildContext context, Item item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemSheet(item: item),
  );
}

class _ItemSheet extends StatefulWidget {
  final Item item;

  const _ItemSheet({
    required this.item,
  });

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  static const int _maxDays = 30;

  bool _loading = false;

  late DateTime _due = DateTime.now().add(
    const Duration(days: 7),
  );

  late Future<bool> _adminFuture;

  @override
  void initState() {
    super.initState();

    // Mengecek role akun yang sedang login.
    _adminFuture = FirestoreService.isAdmin();
  }

  String _day(DateTime d) {
    String t(int n) => n.toString().padLeft(2, '0');

    return '${t(d.day)}/${t(d.month)}/${d.year}';
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(today) ? today : _due,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: _maxDays),
      ),
      helpText: 'Rencana tanggal pengembalian',
    );

    if (picked != null && mounted) {
      setState(() {
        _due = picked;
      });
    }
  }

  Future<void> _borrow() async {
    if (_loading) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() {
      _loading = true;
    });

    try {
      await FirestoreService.borrow(
        widget.item,
        dueDate: _due,
      );

      if (!mounted) return;

      nav.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${widget.item.name} berhasil dipinjam '
            'sampai ${_day(_due)}. '
            'Lihat di Profil > Riwayat.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _duePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _loading ? null : _pickDue,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.alice,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_available_rounded,
              color: AppColors.bell,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rencana pengembalian',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _day(_due),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alice,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.bell,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Akun admin hanya dapat mengelola inventaris, ',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _borrowSection() {
    return FutureBuilder<bool>(
      future: _adminFuture,
      builder: (context, snapshot) {
        // Jika role belum berhasil diperiksa, jangan tampilkan
        // fitur peminjaman.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Role akun tidak dapat diperiksa. '
              'Silakan coba lagi.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final isAdmin = snapshot.data!;

        // ADMIN: hanya melihat informasi alat.
        if (isAdmin) {
          return _adminInfo();
        }

        // USER: alat sedang dipinjam.
        if (!widget.item.available) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Alat ini sedang dipinjam. '
              'Kalau kamu yang meminjam, kembalikan '
              'lewat Profil > Riwayat.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          );
        }

        // USER: alat tersedia dan bisa dipinjam.
        return Column(
          children: [
            _duePicker(),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Pinjam Alat',
              loading: _loading,
              onPressed: _loading ? null : _borrow,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .9,
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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

              const SizedBox(height: 16),

              NetImage(
                e.image,
                width: double.infinity,
                height: 190,
                radius: 20,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(e.status),
                ],
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcon(e.category),
                      size: 16,
                      color: AppColors.bell,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.code} • ${e.category}',
                      style: const TextStyle(
                        color: AppColors.bell,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Spesifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e.spec.isEmpty ? '-' : e.spec,
                  style: const TextStyle(
                    color: AppColors.muted,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tampilan peminjaman menyesuaikan role.
              _borrowSection(),
            ],
          ),
        ),
      ),
    );
  }
}
