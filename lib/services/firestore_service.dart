import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class FirestoreService {
  static final auth = FirebaseAuth.instance;
  static final db = FirebaseFirestore.instance;
  static final items = db.collection('items');
  static final users = db.collection('users');

  static String get uid => auth.currentUser!.uid;

  /// false setelah logout. Dipakai halaman lama supaya tidak membaca Firestore
  /// saat animasi pindah ke LoginScreen (mencegah layar merah sekilas).
  static bool get loggedIn => auth.currentUser != null;

  static CollectionReference<Map<String, dynamic>> get _borrowings =>
      users.doc(uid).collection('borrowings');

  // ---------- AUTH ----------
  static Future<void> login(String email, String pass) =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: pass);

  static Future<void> register({
    required String name,
    required String kelas,
    required String email,
    required String pass,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(), password: pass);
    await saveUser(cred.user!, name.trim(), kelas.trim());
    // isi data dummy inventaris kalau koleksi items masih kosong.
    // Jika gagal, akun tetap berhasil dibuat.
    try {
      await seedIfEmpty();
    } catch (_) {}
  }

  static Future<void> logout() => auth.signOut();

  // ---------- USER ----------
  static Future<void> saveUser(User u, String name, String kelas) {
    return users.doc(u.uid).set({
      'user_id': u.uid,
      'name': name,
      'email': u.email,
      'kelas': kelas,
      'foto': '',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Aman saat logout: kalau user sudah null, kembalikan data kosong.
  static Stream<Map<String, dynamic>> streamUser() {
    final id = auth.currentUser?.uid;
    if (id == null) return Stream.value(<String, dynamic>{});
    return users.doc(id).snapshots().map((d) => d.data() ?? {});
  }

  static Future<void> updatePhoto(String foto) =>
      users.doc(uid).update({'foto': foto});

  /// Edit profil: nama, kelas, dan foto (URL gambar; kosong = tanpa foto).
  static Future<void> updateProfile({
    required String name,
    required String kelas,
    required String foto,
  }) =>
      users.doc(uid).update({
        'name': name.trim(),
        'kelas': kelas.trim(),
        'foto': foto.trim(),
      });

  // ---------- ITEMS (CRUD realtime) ----------
  static Stream<List<Item>> streamItems() => items
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  /// Cek apakah kode alat sudah dipakai (kode harus unik).
  static Future<bool> codeExists(String code, {String? excludeId}) async {
    final snap = await items.where('code', isEqualTo: code).limit(2).get();
    return snap.docs.any((d) => d.id != excludeId);
  }

  /// Alat baru selalu Available. Status hanya berubah lewat pinjam/kembali.
  static Future<void> addItem(Map<String, dynamic> data) async {
    final ref = items.doc();
    await ref.set({
      ...data,
      'item_id': ref.id,
      'status': 'Available',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Alat yang sedang dipinjam tidak boleh diedit.
  static Future<void> updateItem(String id, Map<String, dynamic> data) async {
    final snap = await items.doc(id).get();
    if (snap.data()?['status'] == 'Borrowed') {
      throw Exception('Alat sedang dipinjam, tidak bisa diedit');
    }
    await items.doc(id).update(data);
  }

  /// Alat yang sedang dipinjam tidak boleh dihapus.
  static Future<void> deleteItem(Item item) async {
    final snap = await items.doc(item.id).get();
    if (snap.data()?['status'] == 'Borrowed') {
      throw Exception('Alat sedang dipinjam, tidak bisa dihapus');
    }
    await items.doc(item.id).delete();
  }

  // ---------- PEMINJAMAN & PENGEMBALIAN ----------
  /// Aman saat logout: kalau user sudah null, kembalikan daftar kosong.
  static Stream<List<Borrowing>> streamBorrowings() {
    final id = auth.currentUser?.uid;
    if (id == null) return Stream.value(<Borrowing>[]);
    return users
        .doc(id)
        .collection('borrowings')
        .orderBy('borrow_date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Borrowing.fromDoc).toList());
  }

  /// Transaksi: cegah dua orang meminjam alat yang sama bersamaan.
  static Future<void> borrow(Item item) async {
    final itemRef = items.doc(item.id);
    final ref = _borrowings.doc();
    await db.runTransaction((tx) async {
      final snap = await tx.get(itemRef);
      if (!snap.exists) throw Exception('Alat tidak ditemukan');
      if (snap.data()!['status'] != 'Available') {
        throw Exception('Alat sedang dipinjam orang lain');
      }
      tx.set(ref, {
        'borrow_id': ref.id,
        'item_id': item.id,
        'item_name': item.name,
        'borrow_date': FieldValue.serverTimestamp(),
        'status': 'Dipinjam',
        'return_date': null,
      });
      tx.update(itemRef, {'status': 'Borrowed'});
    });
  }

  /// Dokumen peminjaman TIDAK dihapus, hanya diberi status Dikembalikan
  /// dan tanggal kembali, supaya tercatat di riwayat.
  static Future<void> returnItem(Borrowing b) async {
    await db.runTransaction((tx) async {
      tx.update(_borrowings.doc(b.id), {
        'status': 'Dikembalikan',
        'return_date': FieldValue.serverTimestamp(),
      });
      tx.update(items.doc(b.itemId), {'status': 'Available'});
    });
  }

  // ---------- DATA DUMMY ----------

  /// Nama alat -> URL gambar (dipakai fixImages dan seedIfEmpty).
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

  /// Ganti foto item yang SUDAH ADA di Firestore, dicocokkan lewat nama alat.
  /// Mengembalikan jumlah item yang berhasil diperbarui.
  static Future<int> fixImages() async {
    final snap = await items.get();
    var n = 0;
    for (final d in snap.docs) {
      final url = _imageUrls[d.data()['item_name']];
      if (url != null) {
        await d.reference.update({'image': url});
        n++;
      }
    }
    return n;
  }

  /// Hapus semua item lalu isi ulang dengan data dummy terbaru.
  static Future<void> reseed() async {
    final snap = await items.get();
    final batch = db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    await seedIfEmpty();
  }

  /// Isi data dummy hanya jika koleksi items masih kosong.
  /// Semua alat Available; status Borrowed hanya muncul dari peminjaman asli.
  static Future<void> seedIfEmpty() async {
    final snap = await items.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    // [nama, kategori, kode, spesifikasi]
    final List<List<String>> dummy = [
      ['Mikroskop Binokuler', 'Mikroskop', 'MIK-001',
        'Pembesaran 40x-1000x, lensa binokuler, lampu LED'],
      ['Osiloskop 2 Channel', 'Elektronik', 'ELK-002',
        'Bandwidth 100 MHz, 2 kanal, layar 7 inci'],
      ['Multimeter Digital', 'Elektronik', 'ELK-001',
        'Ukur tegangan, arus, hambatan, auto range'],
      ['Gelas Ukur 100 ml', 'Kimia', 'GLS-001',
        'Borosilikat, skala 1 ml, tahan panas'],
      ['Buret 50 ml', 'Kimia', 'GLS-002', 'Kran PTFE, skala 0,1 ml'],
      ['Mikroskop Monokuler', 'Mikroskop', 'MIK-002',
        'Pembesaran 100x-640x, cocok untuk pemula'],
      ['Power Supply DC', 'Elektronik', 'ELK-003',
        '0-30 V, 0-5 A, tampilan digital'],
      ['Timbangan Digital', 'Kimia', 'KIM-001',
        'Kapasitas 500 g, ketelitian 0,01 g'],
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
        // selisih menit supaya urutan tampilan konsisten
        'created_at':
            Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: i))),
      });
    }
    await batch.commit();
  }
}