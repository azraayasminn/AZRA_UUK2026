import 'dart:convert';
import 'package:flutter/material.dart';

// Palet: Alice Blue, Pale Sky, Sky Reflection, Steel Blue, Blue Bell
class AppColors {
  static const alice = Color(0xFFE2EFF6);
  static const pale = Color(0xFFB7D7EA);
  static const sky = Color(0xFF8DBEDC);
  static const steel = Color(0xFF64A4CE);
  static const bell = Color(0xFF4893C6);
  // turunan supaya teks dan header terbaca
  static const deep = Color(0xFF2B6A9B);
  static const text = Color(0xFF1E4160);
  static const muted = Color(0xFF5F7F99);
  static const available = Color(0xFF4893C6);
  static const borrowed = Color(0xFFE08A3C);
  static const danger = Color(0xFFE5484D);
}

const headerGradient = LinearGradient(
  colors: [AppColors.deep, AppColors.bell, AppColors.steel],
  stops: [0.0, 0.6, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Background halaman: gradasi lembut dari atas ke bawah
const bgGradient = LinearGradient(
  colors: [AppColors.pale, AppColors.alice, Color(0xFFF6FAFD)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kCategories = ['Gelas Ukur', 'Mikroskop', 'Elektronik', 'Kimia', 'Lainnya'];

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.bell, primary: AppColors.bell, secondary: AppColors.steel),
  scaffoldBackgroundColor: AppColors.alice,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.alice,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.bell, width: 1.5),
    ),
  ),
);

List<BoxShadow> get softShadow => [
      BoxShadow(
        color: AppColors.deep.withOpacity(0.14),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

/// Foto bisa berupa link URL atau data base64 (hasil upload dari galeri/kamera).
ImageProvider? photoProvider(String? foto) {
  if (foto == null || foto.isEmpty) return null;
  if (foto.startsWith('data:')) {
    return MemoryImage(base64Decode(foto.split(',').last));
  }
  return NetworkImage(foto);
}

String formatDate(DateTime? d) {
  if (d == null) return '-';
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
}

IconData categoryIcon(String c) {
  switch (c) {
    case 'Mikroskop':
      return Icons.biotech;
    case 'Gelas Ukur':
      return Icons.science;
    case 'Elektronik':
      return Icons.bolt;
    case 'Kimia':
      return Icons.local_fire_department;
    default:
      return Icons.category;
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: bgGradient),
        child: child,
      );
}

PreferredSizeWidget gradientAppBar(String title,
        {List<Widget>? actions, PreferredSizeWidget? bottom}) =>
    AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: headerGradient)),
    );

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  const GradientButton({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: headerGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dipakai untuk status alat (Available/Borrowed) dan status peminjaman (Dipinjam/Dikembalikan).
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final ok = status == 'Available' || status == 'Dikembalikan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? AppColors.available : AppColors.borrowed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(status,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

Widget decoCircle(double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
    );

/// Kerangka Login & Register: header gradasi + sheet putih melengkung.
class AuthShell extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final bool showBack;
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    const headerH = 230.0;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: headerGradient),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, cons) => SingleChildScrollView(
              child: Column(children: [
                SizedBox(
                  height: headerH,
                  child: Stack(children: [
                    Positioned(top: -40, right: -30, child: decoCircle(150, 0.12)),
                    Positioned(bottom: -50, left: -30, child: decoCircle(130, 0.1)),
                    if (showBack)
                      Positioned(
                        left: 8,
                        top: 4,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.science, size: 36, color: AppColors.bell),
                        ),
                        const SizedBox(height: 14),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: Colors.white70)),
                      ]),
                    ),
                  ]),
                ),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                      minHeight: cons.maxHeight > headerH ? cons.maxHeight - headerH : 0.0),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: child,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

