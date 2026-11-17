
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'item_from_screen.dart';
import 'item_sheet.dart';
import 'net_image.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();

  String _query = '';
  String _cat = 'Semua';

  bool _grid = true;
  bool _isAdmin = false;
  bool _roleLoaded = false;

  late final Stream<List<Item>> _stream =
      FirestoreService.streamItems();

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // ================= CEK ROLE =================

  Future<void> _loadRole() async {
    try {
      final admin = await FirestoreService.isAdmin();

      if (!mounted) return;

      setState(() {
        _isAdmin = admin;
        _roleLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAdmin = false;
        _roleLoaded = true;
      });
    }
  }

  // ================= RESPONSIF =================

  int _gridCols(double w) {
    if (w >= 1200) return 5;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  int _listCols(double w) => w >= 900 ? 2 : 1;

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m)),
    );
  }

  // ================= HAPUS ITEM =================

  Future<void> _delete(Item e) async {
    if (!_roleLoaded || !_isAdmin) {
      _snack('Hanya Admin yang boleh menghapus barang');
      return;
    }

    if (!e.available) {
      _snack('${e.name} sedang dipinjam, tidak bisa dihapus');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Hapus alat?'),
        content: Text('${e.name} akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirestoreService.deleteItem(e);

      if (mounted) {
        _snack('${e.name} dihapus');
      }
    } catch (err) {
      if (mounted) {
        _snack(
          err.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  // ================= BUKA FORM =================

  void _openForm([Item? item]) {
    if (!_roleLoaded) {
      _snack('Sedang memeriksa hak akses...');
      return;
    }

    // USER hanya bisa melihat detail dan meminjam.
    if (!_isAdmin) {
      if (item != null) {
        showItemSheet(context, item);
      }
      return;
    }

    // ADMIN tidak boleh mengedit alat yang sedang dipinjam.
    if (item != null && !item.available) {
      _snack(
        '${item.name} sedang dipinjam, tidak bisa diedit',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(item: item),
      ),
    );
  }

  // ================= TAMPILAN KARTU =================

  Widget _dim(Item e, Widget child) {
    return AnimatedOpacity(
      opacity: e.available ? 1 : 0.78,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // Tombol tambah hanya muncul untuk ADMIN.
        floatingActionButton:
            (_roleLoaded && _isAdmin)
                ? Container(
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: softShadow,
                    ),
                    child: FloatingActionButton.extended(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      highlightElevation: 0,
                      foregroundColor: Colors.white,
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,

        body: StreamBuilder<List<Item>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text('Error: ${snap.error}'),
              );
            }

            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final all = snap.data!;
            final q = _query.toLowerCase();

            final list = all.where((e) {
              return (_cat == 'Semua' || e.category == _cat) &&
                  (q.isEmpty ||
                      e.name.toLowerCase().contains(q) ||
                      e.code.toLowerCase().contains(q));
            }).toList();

            final avail =
                all.where((e) => e.available).length;

            return LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final pad = w >= 600 ? 24.0 : 16.0;

                final gridCols = _gridCols(w);
                final listCols = _listCols(w);

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _header(
                        context,
                        all.length,
                        avail,
                        pad,
                      ),
                    ),

                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedBar(
                        height: 64,
                        child: _chips(all, pad),
                      ),
                    ),

                    if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _empty(),
                      )

                    else if (_grid)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          8,
                          pad,
                          110,
                        ),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _Appear(
                              key: ValueKey('g-${list[i].id}'),
                              index: i,
                              child: _dim(
                                list[i],
                                _gridCard(list[i]),
                              ),
                            ),
                            childCount: list.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridCols,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 235,
                          ),
                        ),
                      )

                    else if (listCols == 1)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          8,
                          pad,
                          110,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _Appear(
                              key: ValueKey('l-${list[i].id}'),
                              index: i,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: _dim(
                                  list[i],
                                  _listCard(list[i]),
                                ),
                              ),
                            ),
                            childCount: list.length,
                          ),
                        ),
                      )

                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          8,
                          pad,
                          110,
                        ),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _Appear(
                              key: ValueKey('l-${list[i].id}'),
                              index: i,
                              child: _dim(
                                list[i],
                                _listCard(list[i]),
                              ),
                            ),
                            childCount: list.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: listCols,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 110,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(
    BuildContext context,
    int total,
    int avail,
    double pad,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pad + 4,
        MediaQuery.of(context).padding.top + 18,
        pad + 4,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventaris',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total alat terdaftar',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: glassDecoration(
                  radius: 24,
                  opacity: .6,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _grid = !_grid;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 220,
                        ),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(
                          scale: a,
                          child: c,
                        ),
                        child: Icon(
                          _grid
                              ? Icons.view_agenda_rounded
                              : Icons.grid_view_rounded,
                          key: ValueKey(_grid),
                          color: AppColors.deep,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _pill(
                Icons.inventory_2_rounded,
                total,
                'Total',
              ),
              const SizedBox(width: 10),
              _pill(
                Icons.check_circle_rounded,
                avail,
                'Tersedia',
              ),
              const SizedBox(width: 10),
              _pill(
                Icons.schedule_rounded,
                total - avail,
                'Dipinjam',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            decoration: glassDecoration(
              radius: 20,
              opacity: .75,
            ),
            child: TextField(
              controller: _search,
              onChanged: (v) {
                setState(() {
                  _query = v.trim();
                });
              },
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode alat...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.bell,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.muted,
                        ),
                        onPressed: () {
                          setState(() {
                            _search.clear();
                            _query = '';
                          });
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    IconData icon,
    int n,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: glassDecoration(
          radius: 20,
          opacity: .55,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.bell,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              '$n',
              style: const TextStyle(
                color: AppColors.deep,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CHIP KATEGORI =================

  Widget _chips(List<Item> all, double pad) {
    final cats = ['Semua', ...kCategories];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: pad,
        vertical: 9,
      ),
      itemCount: cats.length,
      separatorBuilder: (_, __) =>
          const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final c = cats[i];
        final sel = _cat == c;

        final n = c == 'Semua'
            ? all.length
            : all.where((e) => e.category == c).length;

        return GestureDetector(
          onTap: () {
            setState(() {
              _cat = c;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: sel
                  ? null
                  : Colors.white.withOpacity(.55),
              gradient: sel ? headerGradient : null,
              borderRadius: BorderRadius.circular(22),
              border: sel
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(.75),
                    ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.bell.withOpacity(.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c == 'Semua'
                      ? Icons.apps_rounded
                      : categoryIcon(c),
                  size: 16,
                  color: sel ? Colors.white : AppColors.bell,
                ),
                const SizedBox(width: 6),
                Text(
                  c,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? Colors.white.withOpacity(.25)
                        : Colors.white.withOpacity(.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sel
                          ? Colors.white
                          : AppColors.deep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= MENU ADMIN =================

  Widget _menuButton(
    Item e, {
    bool onPhoto = false,
  }) {
    // Menu edit dan hapus hanya untuk admin.
    if (!_roleLoaded || !_isAdmin) {
      return const SizedBox.shrink();
    }

    final bg = Colors.white.withOpacity(
      onPhoto ? .92 : .8,
    );

    if (!e.available) {
      return Tooltip(
        message: 'Sedang dipinjam',
        child: GestureDetector(
          onTap: () {
            _snack(
              '${e.name} sedang dipinjam, '
              'tidak bisa diedit atau dihapus',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Opsi',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (v) {
        if (v == 'edit') {
          _openForm(e);
        } else if (v == 'delete') {
          _delete(e);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.bell,
              ),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.danger,
              ),
              SizedBox(width: 10),
              Text(
                'Hapus',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: AppColors.text,
        ),
      ),
    );
  }

  // ================= KARTU GRID =================

  Widget _gridCard(Item e) {
    return GestureDetector(
      onTap: () => _openForm(e),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: glassDecoration(
          radius: 24,
          opacity: .6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetImage(
                      e.image,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: StatusBadge(e.status),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _menuButton(
                      e,
                      onPhoto: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        categoryIcon(e.category),
                        size: 13,
                        color: AppColors.bell,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${e.code} • ${e.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= KARTU DAFTAR =================

  Widget _listCard(Item e) {
    return GestureDetector(
      onTap: () => _openForm(e),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: glassDecoration(
          radius: 24,
          opacity: .6,
        ),
        child: Row(
          children: [
            NetImage(
              e.image,
              width: 84,
              height: 84,
              radius: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        categoryIcon(e.category),
                        size: 14,
                        color: AppColors.bell,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${e.code} • ${e.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(e.status),
                ],
              ),
            ),
            _menuButton(e),
          ],
        ),
      ),
    );
  }

  // ================= KOSONG =================

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: glassDecoration(
                radius: 42,
                opacity: .6,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada alat yang cocok',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba kata kunci atau kategori lain',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PINNED BAR =================

class _PinnedBar extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedBar({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlaps,
  ) {
    final bar = Container(
      decoration: BoxDecoration(
        color: overlaps
            ? Colors.white.withOpacity(.55)
            : Colors.transparent,
        border: overlaps
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(.75),
                ),
              )
            : null,
      ),
      child: child,
    );

    if (!overlaps) return bar;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: bar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

// ================= ANIMASI KARTU =================

class _Appear extends StatelessWidget {
  final int index;
  final Widget child;

  const _Appear({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 350 + math.min(index, 8) * 60,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
