import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'common.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  // tiap elemen punya jadwal sendiri dalam 3 detik
  late final Animation<double> _logo = CurvedAnimation(
      parent: _c, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut));
  late final Animation<double> _text = CurvedAnimation(
      parent: _c, curve: const Interval(0.25, 0.6, curve: Curves.easeOut));
  late final Animation<double> _bar = CurvedAnimation(
      parent: _c, curve: const Interval(0.1, 1.0, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    _c.forward();
  }

  void _goNext() {
    if (!mounted) return;
    final logged = FirebaseAuth.instance.currentUser != null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => logged ? const MainShell() : const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: headerGradient),
        child: Stack(children: [
          Positioned(
              top: -70,
              right: -60,
              child: _FloatingGlow(
                  controller: _c, size: 260, opacity: 0.30, direction: 1)),
          Positioned(
              bottom: -90,
              left: -70,
              child: _FloatingGlow(
                  controller: _c, size: 300, opacity: 0.22, direction: -1)),
          Center(child: _Brand(logo: _logo, text: _text)),
          Positioned(
              bottom: 56,
              left: 48,
              right: 48,
              child: _LoadingBar(progress: _bar)),
        ]),
      ),
    );
  }
}

/// Lingkaran cahaya lembut yang bergerak naik-turun pelan.
class _FloatingGlow extends StatelessWidget {
  final Animation<double> controller;
  final double size, opacity;
  final int direction; // 1 atau -1, supaya dua lingkaran bergerak berlawanan

  const _FloatingGlow({
    required this.controller,
    required this.size,
    required this.opacity,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            0, direction * math.sin(controller.value * 2 * math.pi) * 14),
        child: child,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(0),
          ]),
        ),
      ),
    );
  }
}

/// Logo kaca + nama aplikasi + tagline, muncul bertahap.
class _Brand extends StatelessWidget {
  final Animation<double> logo, text;
  const _Brand({required this.logo, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: logo,
        builder: (_, child) => Opacity(
          opacity: logo.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * logo.value, child: child),
        ),
        child: const _GlassLogo(),
      ),
      const SizedBox(height: 28),
      AnimatedBuilder(
        animation: text,
        builder: (_, child) => Opacity(
          opacity: text.value.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - text.value)), child: child),
        ),
        child: const Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Cata',
                      style: TextStyle(fontWeight: FontWeight.w300)),
                  TextSpan(
                      text: 'Lab',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ]),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                    color: Colors.white, fontSize: 32, letterSpacing: 1),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text('Kelola Alat dan Bahan Lab',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.alice, fontSize: 14, letterSpacing: 0.4)),
        ]),
      ),
    ]);
  }
}

class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (r) => headerGradient.createShader(r),
              child: const Icon(Icons.science, size: 52, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bar yang terisi mengikuti animasi.
class _LoadingBar extends StatelessWidget {
  final Animation<double> progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: progress,
          builder: (_, __) => LinearProgressIndicator(
            value: progress.value,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.28),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Text('Memuat...',
          style: TextStyle(color: AppColors.alice, fontSize: 12)),
    ]);
  }
}