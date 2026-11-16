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
  final DateTime? borrowDate, returnDate;
  Borrowing({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.status,
    this.borrowDate,
    this.returnDate,
  });

  bool get active => status == 'Dipinjam';

  factory Borrowing.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Borrowing(
      id: d.id,
      itemId: m['item_id'] ?? '',
      itemName: m['item_name'] ?? '',
      // data lama (tanpa field status) dianggap masih dipinjam
      status: m['status'] ?? 'Dipinjam',
      borrowDate: (m['borrow_date'] as Timestamp?)?.toDate(),
      returnDate: (m['return_date'] as Timestamp?)?.toDate(),
    );
  }
}