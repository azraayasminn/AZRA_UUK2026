import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart' as firestore_service;
import 'common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Tanggal saja (tanpa jam), untuk rencana pengembalian.
  String _day(DateTime? d) {
    if (d == null) return '-';
    String t(int n) => n.toString().padLeft(2, '0');
    return '${t(d.day)}/${t(d.month)}/${d.year}';
  }

  Future<void> _return(BuildContext context, Borrowing b) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kembalikan alat?'),
        content: Text('${b.itemName} akan ditandai sudah dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kembalikan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestore_service.FirestoreService.returnItem(b);
      messenger.showSnackBar(SnackBar(content: Text('${b.itemName} berhasil dikembalikan')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal mengembalikan: $e')));
    }
  }

  /// Satu baris informasi: ikon, label (lebar tetap), dan nilai.
  Widget _info(IconData icon, Color iconColor, String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 104,
          child: Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? AppColors.text)),
        ),
      ]),
    );
  }

  Widget _lateTag(int days) => Container(
        margin: const EdgeInsets.only(top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: AppColors.danger),
          const SizedBox(width: 6),
          Text('Terlambat $days hari',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger)),
        ]),
      );

  Widget _card(BuildContext context, Borrowing b) {
    final borrower = b.borrowerName.isEmpty ? '-' : b.borrowerName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // nama barang + status peminjaman
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                gradient: headerGradient, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.science, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(b.itemName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.text))),
          const SizedBox(width: 8),
          StatusBadge(b.status),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.alice),
        const SizedBox(height: 12),

        _info(Icons.person_outline_rounded, AppColors.bell, 'Peminjam', borrower),
        _info(Icons.inventory_2_outlined, AppColors.bell, 'Nama barang', b.itemName),
        _info(Icons.north_east, AppColors.borrowed, 'Tgl pinjam',
            formatDate(b.borrowDate)),
        _info(Icons.event_available_outlined, AppColors.bell, 'Rencana kembali',
            _day(b.dueDate)),
        _info(
          Icons.south_west,
          AppColors.available,
          'Tgl kembali',
          b.active ? 'Belum dikembalikan' : formatDate(b.returnDate),
          valueColor: b.active ? AppColors.muted : AppColors.text,
        ),
        _info(
          Icons.flag_outlined,
          b.active ? AppColors.borrowed : AppColors.available,
          'Status',
          b.status,
          bold: true,
          valueColor: b.active ? AppColors.borrowed : AppColors.available,
        ),
        if (b.late) _lateTag(b.lateDays),

        if (b.active) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bell,
                side: const BorderSide(color: AppColors.bell),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Kembalikan'),
              onPressed: () => _return(context, b),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _list(BuildContext context, List<Borrowing> list, String empty) {
    if (list.isEmpty) {
      return Center(child: Text(empty, style: const TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _card(context, list[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: gradientAppBar(
          'Riwayat Peminjaman',
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Sedang Dipinjam'), Tab(text: 'Semua Riwayat')],
          ),
        ),
        body: AppBackground(
          child: StreamBuilder<List<Borrowing>>(
            stream: firestore_service.FirestoreService.streamBorrowings(),
            builder: (context, snap) {
              // setelah logout, jangan bangun apa pun (mencegah layar merah)
              if (!firestore_service.FirestoreService.loggedIn) {
                return const SizedBox.shrink();
              }
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final all = snap.data!;
              return TabBarView(children: [
                _list(context, all.where((b) => b.active).toList(),
                    'Tidak ada alat yang sedang dipinjam'),
                _list(context, all, 'Belum ada riwayat peminjaman'),
              ]);
            },
          ),
        ),
      ),
    );
  }
}