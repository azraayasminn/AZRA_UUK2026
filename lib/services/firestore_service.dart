
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class FirestoreService {
  static final auth = FirebaseAuth.instance;
  static final db = FirebaseFirestore.instance;
  static final items = db.collection('items');
  static final users = db.collection('users');

  static String get uid => auth.currentUser!.uid;

  static bool get loggedIn => auth.currentUser != null;

  static CollectionReference<Map<String, dynamic>> get _borrowings =>
      users.doc(uid).collection('borrowings');

  // ================= AUTH =================

  static Future<UserCredential> login(
    String email,
    String pass,
  ) {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: pass,
    );
  }

  static Future<void> register({
    required String name,
    required String kelas,
    required String email,
    required String pass,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: pass,
    );

    await saveUser(
      cred.user!,
      name.trim(),
      kelas.trim(),
    );

    try {
      await seedIfEmpty();
    } catch (_) {}
  }

  static Future<void> logout() => auth.signOut();

  // ================= ROLE / ADMIN =================

  static Future<bool> isAdmin() async {
    final user = auth.currentUser;

    if (user == null) return false;

    final doc = await users.doc(user.uid).get();
    final data = doc.data();

    if (data == null) return false;

    return data['role'] == 'admin';
  }

  static Future<void> _requireAdmin() async {
    if (!await isAdmin()) {
      throw Exception('Akses ditolak. Khusus Admin.');
    }
  }

  static Future<void> _requireUser() async {
    if (!loggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    if (await isAdmin()) {
      throw Exception(
        'Akun admin hanya dapat mengelola inventaris, bukan meminjam alat.',
      );
    }
  }

  // ================= USER =================

  static Future<void> saveUser(
    User u,
    String name,
    String kelas,
  ) {
    return users.doc(u.uid).set({
      'user_id': u.uid,
      'name': name,
      'email': u.email,
      'kelas': kelas,
      'foto': '',
      'role': 'user',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, dynamic>> streamUser() {
    final id = auth.currentUser?.uid;

    if (id == null) {
      return Stream.value(<String, dynamic>{});
    }

    return users.doc(id).snapshots().map(
      (d) => d.data() ?? {},
    );
  }

  static Future<void> updatePhoto(String foto) {
    return users.doc(uid).update({
      'foto': foto,
    });
  }

  static Future<void> updateProfile({
    required String name,
    required String kelas,
    required String foto,
  }) {
    return users.doc(uid).update({
      'name': name.trim(),
      'kelas': kelas.trim(),
      'foto': foto.trim(),
    });
  }

  // ================= ITEMS =================

  static Stream<List<Item>> streamItems() {
    return items.snapshots().map((s) {
      final docs = s.docs.toList();

      int ms(QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final t = d.data()['created_at'];
        return t is Timestamp ? t.millisecondsSinceEpoch : 0;
      }

      docs.sort((a, b) => ms(b).compareTo(ms(a)));

      return docs.map(Item.fromDoc).toList();
    });
  }

  static Future<bool> codeExists(
    String code, {
    String? excludeId,
  }) async {
    final snap = await items
        .where('code', isEqualTo: code)
        .limit(2)
        .get();

    return snap.docs.any((d) => d.id != excludeId);
  }

  static Future<void> addItem(
    Map<String, dynamic> data,
  ) async {
    await _requireAdmin();

    final ref = items.doc();

    await ref.set({
      ...data,
      'item_id': ref.id,
      'status': 'Available',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _requireAdmin();

    final snap = await items.doc(id).get();

    if (!snap.exists) {
      throw Exception('Alat tidak ditemukan');
    }

    if (snap.data()?['status'] == 'Borrowed') {
      throw Exception('Alat sedang dipinjam, tidak bisa diedit');
    }

    await items.doc(id).update(data);
  }

  static Future<void> deleteItem(Item item) async {
    await _requireAdmin();

    final snap = await items.doc(item.id).get();

    if (!snap.exists) {
      throw Exception('Alat tidak ditemukan');
    }

    if (snap.data()?['status'] == 'Borrowed') {
      throw Exception('Alat sedang dipinjam, tidak bisa dihapus');
    }

    await items.doc(item.id).delete();
  }

  // ================= PEMINJAMAN =================

  static Stream<List<Borrowing>> streamBorrowings() {
    final id = auth.currentUser?.uid;

    if (id == null) {
      return Stream.value(<Borrowing>[]);
    }

    return users
        .doc(id)
        .collection('borrowings')
        .orderBy('borrow_date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map(Borrowing.fromDoc).toList(),
        );
  }

  static Future<void> borrow(
    Item item, {
    required DateTime dueDate,
  }) async {
    // ADMIN DILARANG MEMINJAM
    await _requireUser();

    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    if (dueDate.isBefore(startOfToday)) {
      throw Exception(
        'Rencana pengembalian tidak boleh sebelum hari ini',
      );
    }

    final due = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );

    final userSnap = await users.doc(uid).get();

    final name = (
      userSnap.data()?['name'] ??
      auth.currentUser?.displayName ??
      auth.currentUser?.email ??
      ''
    ).toString();

    final itemRef = items.doc(item.id);
    final ref = _borrowings.doc();

    await db.runTransaction((tx) async {
      final snap = await tx.get(itemRef);

      if (!snap.exists) {
        throw Exception('Alat tidak ditemukan');
      }

      if (snap.data()?['status'] != 'Available') {
        throw Exception('Alat sedang dipinjam orang lain');
      }

      tx.set(ref, {
        'borrow_id': ref.id,
        'item_id': item.id,
        'item_name': item.name,
        'borrower_id': uid,
        'borrower_name': name,
        'borrow_date': FieldValue.serverTimestamp(),
        'due_date': Timestamp.fromDate(due),
        'status': 'Dipinjam',
        'return_date': null,
      });

      tx.update(itemRef, {
        'status': 'Borrowed',
      });
    });
  }

  // ================= PENGEMBALIAN =================

  static Future<void> returnItem(Borrowing b) async {
    if (!loggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    await db.runTransaction((tx) async {
      tx.update(_borrowings.doc(b.id), {
        'status': 'Dikembalikan',
        'return_date': FieldValue.serverTimestamp(),
      });

      tx.update(items.doc(b.itemId), {
        'status': 'Available',
      });
    });
  }

  // ================= GAMBAR ITEM =================

  static const Map<String, String> _imageUrls = {
    'Mikroskop Binokuler':
        'https://andarupm.co.id/wp-content/uploads/2019/09/jual-mikroskop-monokuler-untuk-universitas.png',

    'Osiloskop 2 Channel':
        'https://www.kucari.com/wp-content/uploads/2022/09/Osciloscope-20-Mhz.jpg',

    'Multimeter Digital':
        'https://upload.jaknot.com/2021/12/images/products/8e8a8c/original/aneng-digital-multimeter-voltage-tester-dm850.jpg',

    'Gelas Ukur 100 ml':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTIQAaWi7L9HQXDfYzHmniGU577AOidJtCWrWyfimJujKZoxI7thuUUkJk&s=10',

    'Buret 50 ml':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTH6shEpxfTQk_TNFs_m6alwcyQAAEyLgGeHBLQ8L-fhZcvynPkkurpUtY&s=10',

    'Mikroskop Monokuler':
        'https://pusatalatlaboratorium.com/wp-content/uploads/2018/09/B-150POL-MR_model.jpg',

    'Power Supply DC':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQLDvPvalQYFDLppVTB9genTk-2NHH-JBYiGyxGTFY7G-1Lg0da8-Z1-lHL&s=10',

    'Timbangan Digital':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS_L9t8ZPQbni_XTFbl7D6yw1K3wVjeJ4r59hBGqQXrL9ARbbJzG_25kd0&s=10',
  };

  static Future<int> fixImages() async {
    await _requireAdmin();

    final snap = await items.get();
    var n = 0;

    for (final d in snap.docs) {
      final url = _imageUrls[d.data()['item_name']];

      if (url != null) {
        await d.reference.update({
          'image': url,
        });
        n++;
      }
    }

    return n;
  }

  // ================= DATA DUMMY =================

  static Future<void> reseed() async {
    await _requireAdmin();

    final snap = await items.get();
    final batch = db.batch();

    for (final d in snap.docs) {
      batch.delete(d.reference);
    }

    await batch.commit();
    await seedIfEmpty();
  }

  static Future<void> seedIfEmpty() async {
    final snap = await items.limit(1).get();

    if (snap.docs.isNotEmpty) return;

    final List<List<String>> dummy = [
      [
        'Mikroskop Binokuler',
        'Mikroskop',
        'MIK-001',
        'Pembesaran 40x-1000x, lensa binokuler, lampu LED',
      ],
      [
        'Osiloskop 2 Channel',
        'Elektronik',
        'ELK-002',
        'Bandwidth 100 MHz, 2 kanal, layar 7 inci',
      ],
      [
        'Multimeter Digital',
        'Elektronik',
        'ELK-001',
        'Ukur tegangan, arus, hambatan, auto range',
      ],
      [
        'Gelas Ukur 100 ml',
        'Kimia',
        'GLS-001',
        'Borosilikat, skala 1 ml, tahan panas',
      ],
      [
        'Buret 50 ml',
        'Kimia',
        'GLS-002',
        'Kran PTFE, skala 0,1 ml',
      ],
      [
        'Mikroskop Monokuler',
        'Mikroskop',
        'MIK-002',
        'Pembesaran 100x-640x, cocok untuk pemula',
      ],
      [
        'Power Supply DC',
        'Elektronik',
        'ELK-003',
        '0-30 V, 0-5 A, tampilan digital',
      ],
      [
        'Timbangan Digital',
        'Kimia',
        'KIM-001',
        'Kapasitas 500 g, ketelitian 0,01 g',
      ],
    ];

    final batch = db.batch();

    for (var i = 0; i < dummy.length; i++) {
      final d = dummy[i];
      final ref = items.doc();

      batch.set(ref, {
        'item_id': ref.id,
        'item_name': d[0],
        'category': d[1],
        'code': d[2],
        'status': 'Available',
        'image': _imageUrls[d[0]] ?? '',
        'spesification': d[3],
        'created_at': Timestamp.fromDate(
          DateTime.now().subtract(
            Duration(minutes: i),
          ),
        ),
      });
    }

    await batch.commit();
  }
}
