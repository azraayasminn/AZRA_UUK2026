import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart' as firestore_service;
import 'common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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

  Widget _card(BuildContext context, Borrowing b) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text))),
            StatusBadge(b.status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.north_east, size: 16, color: AppColors.borrowed),
            const SizedBox(width: 6),
            Text('Dipinjam: ${formatDate(b.borrowDate)}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ]),
          if (!b.active) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.south_west, size: 16, color: AppColors.available),
              const SizedBox(width: 6),
              Text('Dikembalikan: ${formatDate(b.returnDate)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
          ],
          if (b.active) ...[
            const SizedBox(height: 12),
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