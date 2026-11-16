import 'dart:async';
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'item_sheet.dart';
import 'net_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _q = '';

  // stream dibuat SEKALI supaya tidak berkedip saat mengetik di kolom cari
  late final Stream<List<Item>> _itemsStream = FirestoreService.streamItems();
  late final Stream<Map<String, dynamic>> _userStream =
      FirestoreService.streamUser();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Item>>(
        stream: _itemsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          final q = _q.toLowerCase();
          final results = items
              .where((e) =>
                  e.name.toLowerCase().contains(q) ||
                  e.code.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q))
              .toList();
          final cats = items.map((e) => e.category).toSet().toList();
          final avail = items.where((e) => e.available).length;
          final borrowed = items.length - avail;

          return CustomScrollView(
            slivers: [
              // Header yang menyusut: "Halo, nama" hilang saat di-scroll,
              // kolom pencarian tetap menempel di atas.
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  topPad: MediaQuery.of(context).padding.top,
                  greeting: _greeting(),
                  searchField: _searchField(),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (!snap.hasData)
                    const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_q.isNotEmpty) ...[
                    _title('Hasil pencarian (${results.length})'),
                    if (results.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Alat tidak ditemukan')))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: results
                              .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ItemTile(item: e)))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const _BannerCarousel(),
                    _title('Semua Data'),
                    if (items.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Belum ada data alat')))
                    else
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => _itemCard(context, items[i]),
                        ),
                      ),
                    _title('Kategori Peralatan'),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => ActionChip(
                          onPressed: () => setState(() {
                            _search.text = cats[i];
                            _q = cats[i];
                          }),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                          avatar: Icon(categoryIcon(cats[i]),
                              size: 16, color: AppColors.bell),
                          label: Text(cats[i],
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 12)),
                        ),
                      ),
                    ),
                    _title('Status'),
                    SizedBox(
                      height: 70,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _statusCard('Available', avail, AppColors.bell,
                              Icons.check_circle_outline),
                          const SizedBox(width: 12),
                          _statusCard('Borrowed', borrowed, AppColors.borrowed,
                              Icons.schedule),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- bagian header ----------
  Widget _greeting() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Halo,',
              style: TextStyle(color: AppColors.alice, fontSize: 12)),
          StreamBuilder<Map<String, dynamic>>(
            stream: _userStream,
            builder: (_, s) => Text((s.data?['name'] as String?) ?? '...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );

  Widget _searchField() => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _q = v.trim()),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Cari alat inventaris...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.steel),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.bell),
          suffixIcon: _q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                        _search.clear();
                        _q = '';
                      })),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none),
        ),
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.text)),
      );

  Widget _miniBadge(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: ok ? AppColors.available : AppColors.borrowed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(ok ? 'Tersedia' : 'Dipinjam',
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      );

  Widget _itemCard(BuildContext context, Item e) => GestureDetector(
        onTap: () => showItemSheet(context, e), // di sini ada tombol Pinjam
        child: Container(
          width: 120,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(children: [
                  NetImage(e.image, width: 120, height: 100),
                  Positioned(left: 6, top: 6, child: _miniBadge(e.available)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(e.category,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.steel)),
              ),
            ],
          ),
        ),
      );

  Widget _statusCard(String label, int n, Color c, IconData icon) => Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text('$n alat',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ],
        ),
      );
}

/// Header gradasi yang menyusut saat di-scroll:
/// - "Halo, nama" memudar lalu hilang
/// - kolom pencarian tetap menempel di atas
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPad;
  final Widget greeting;
  final Widget searchField;

  _HomeHeaderDelegate({
    required this.topPad,
    required this.greeting,
    required this.searchField,
  });

  static const _searchH = 48.0;
  static const _greetH = 50.0;

  // tinggi penuh: status bar + sapaan + kolom cari
  @override
  double get maxExtent => topPad + 16 + _greetH + 14 + _searchH + 18;

  // tinggi saat menempel: status bar + kolom cari saja
  @override
  double get minExtent => topPad + 10 + _searchH + 12;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: headerGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        // bayangan muncul perlahan saat header menempel
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withOpacity(0.22 * t),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(children: [
        // sapaan: naik sedikit sambil memudar
        Positioned(
          left: 20,
          right: 20,
          top: topPad + 16 - 20 * t,
          child: Opacity(
            opacity: (1 - t * 1.8).clamp(0.0, 1.0),
            child: SizedBox(height: _greetH, child: greeting),
          ),
        ),
        // kolom pencarian: selalu terlihat
        Positioned(
          left: 20,
          right: 20,
          bottom: 18 - 6 * t,
          height: _searchH,
          child: searchField,
        ),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) => true;
}

/// Baris alat untuk hasil pencarian. Ketuk -> detail + tombol Pinjam.
class ItemTile extends StatelessWidget {
  final Item item;
  const ItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showItemSheet(context, item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            NetImage(item.image, width: 62, height: 62, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 14, color: AppColors.steel),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.steel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.available ? 'Tersedia' : 'Sedang dipinjam',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.available
                          ? AppColors.bell
                          : AppColors.borrowed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.steel),
          ],
        ),
      ),
    );
  }
}

/// Carousel banner (auto-slide) tanpa dependency tambahan
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();
  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _ctrl = PageController(viewportFraction: .92);
  Timer? _timer;
  int _page = 0;

  // [judul, subjudul, URL gambar]
  static const _banners = [
    ['Peralatan Lab Lengkap', 'Mikroskop, elektronik, kimia', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLru90v18a-JDtHiZ1nwiipRzRG84DNHTaUri9q5-SZbPzlXNLwGqp6z2j&s=10'],
    ['Pinjam dengan Mudah', 'Cukup beberapa ketukan', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnltcFCEqVhok9F-Ih238rqffNoS_JMdjacmiWRD0C-PgH9XUJJvhs85VM&s=10'],
    ['Data Real-time', 'Status alat selalu terbarui', 'https://blog.fusionmedstaff.com/hubfs/FMS%20Blog%20Images/GettyImages-1413606459-min.jpg'],
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_ctrl.hasClients) return;
      _ctrl.animateToPage((_page + 1) % _banners.length,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: headerGradient,
                  image: DecorationImage(
                    image: NetworkImage(b[2]),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        AppColors.bell.withOpacity(.6), BlendMode.srcOver),
                    onError: (_, __) {},
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b[0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(b[1],
                        style: const TextStyle(
                            color: AppColors.alice, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                  color: i == _page ? AppColors.bell : AppColors.pale,
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
      ],
    );
  }
}