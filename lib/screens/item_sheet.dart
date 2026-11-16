import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'net_image.dart';

/// Dipanggil dari Beranda. Di sinilah satu-satunya tombol "Pinjam".
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
  const _ItemSheet({required this.item});
  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  bool _loading = false;

  Future<void> _borrow() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await FirestoreService.borrow(widget.item);
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(
              '${widget.item.name} berhasil dipinjam. Lihat di Profil > Riwayat.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 16),
            NetImage(e.image,
                width: double.infinity, height: 190, radius: 20),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: Text(e.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text))),
              const SizedBox(width: 8),
              StatusBadge(e.status),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(categoryIcon(e.category), size: 16, color: AppColors.bell),
                const SizedBox(width: 6),
                Text('${e.code} • ${e.category}',
                    style: const TextStyle(color: AppColors.bell)),
              ]),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Spesifikasi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.text)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(e.spec.isEmpty ? '-' : e.spec,
                  style: const TextStyle(color: AppColors.muted)),
            ),
            if (!e.available) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Alat ini sedang dipinjam. Kalau kamu yang meminjam, kembalikan lewat Profil > Riwayat.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            ],
            const SizedBox(height: 20),
            GradientButton(
              text: e.available ? 'Pinjam Alat' : 'Sedang Dipinjam',
              loading: _loading,
              onPressed: (e.available && !_loading) ? _borrow : null,
            ),
          ]),
        ),
      ),
    );
  }
}