import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id, name, category, code, status, image, spec;
  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.status,
    required this.image,
    required this.spec,
  });

  bool get available => status == 'Available';

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Item(
      id: d.id,
      name: m['item_name'] ?? '',
      category: m['category'] ?? '',
      code: m['code'] ?? '',
      status: m['status'] ?? 'Available',
      image: m['image'] ?? '',
      spec: m['spesification'] ?? '',
    );
  }
}

class Borrowing {
  final String id, itemId, itemName, status; // status: Dipinjam / Dikembalikan
  final String borrowerId, borrowerName;
  final DateTime? borrowDate; // tanggal peminjaman
  final DateTime? dueDate; // rencana tanggal pengembalian
  final DateTime? returnDate; // tanggal pengembalian sebenarnya

  Borrowing({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.status,
    this.borrowerId = '',
    this.borrowerName = '',
    this.borrowDate,
    this.dueDate,
    this.returnDate,
  });

  bool get active => status == 'Dipinjam';

  /// Jumlah hari keterlambatan (0 kalau tidak terlambat atau belum ada rencana).
  /// Alat yang masih dipinjam dihitung sampai sekarang; yang sudah kembali
  /// dihitung sampai tanggal kembali sebenarnya.
  int get lateDays {
    final due = dueDate;
    if (due == null) return 0;
    final end = active ? DateTime.now() : returnDate;
    if (end == null || !end.isAfter(due)) return 0;
    return (end.difference(due).inSeconds / 86400).ceil();
  }

  bool get late => lateDays > 0;

  factory Borrowing.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Borrowing(
      id: d.id,
      itemId: m['item_id'] ?? '',
      itemName: m['item_name'] ?? '',
      // data lama (tanpa field status) dianggap masih dipinjam
      status: m['status'] ?? 'Dipinjam',
      // data lama (tanpa field ini) dibiarkan kosong, ditampilkan sebagai "-"
      borrowerId: m['borrower_id'] ?? '',
      borrowerName: m['borrower_name'] ?? '',
      borrowDate: (m['borrow_date'] as Timestamp?)?.toDate(),
      dueDate: (m['due_date'] as Timestamp?)?.toDate(),
      returnDate: (m['return_date'] as Timestamp?)?.toDate(),
    );
  }
}