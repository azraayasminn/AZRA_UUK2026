import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _NavData {
  final IconData icon, activeIcon;
  final String label;
  const _NavData(this.icon, this.activeIcon, this.label);
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [HomeScreen(), InventoryScreen(), ProfileScreen()];

  static const _items = [
    _NavData(Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    _NavData(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventaris'),
    _NavData(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // background gradasi dipasang sekali di sini, halaman anak transparan
      body: AppBackground(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar:
          _FloatingNav(index: _index, items: _items, onTap: _go),
    );
  }
}

/// Navbar melayang dengan pill gradien yang meluncur ke menu aktif.
class _FloatingNav extends StatelessWidget {
  final int index;
  final List<_NavData> items;
  final ValueChanged<int> onTap;
  const _FloatingNav(
      {required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: AppColors.deep.withOpacity(.22),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(builder: (context, cons) {
            final w = cons.maxWidth / items.length;
            return Stack(children: [
              // pill yang meluncur
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bell.withOpacity(.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(items.length, (i) {
                  final it = items[i];
                  final sel = i == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: sel ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                sel ? it.activeIcon : it.icon,
                                size: 24,
                                color: sel ? Colors.white : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.w500,
                                color: sel ? Colors.white : AppColors.muted,
                              ),
                              child: Text(it.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}