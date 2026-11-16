import 'dart:convert';
import 'package:flutter/material.dart';
import 'common.dart';

/// Gambar dari URL (atau data base64) yang lebih tahan banting:
/// - URL dibersihkan (spasi dibuang, http -> https)
/// - di Flutter Web memakai <img> bila fetch kena blokir CORS (Flutter 3.22+)
/// - ada indikator loading dan placeholder saat gagal
/// - penyebab gagal dicetak di terminal: "GAGAL MUAT FOTO: ..."
class NetImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  final double radius;

  const NetImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });

  double get _iconSize {
    final base =
        height ?? ((width != null && width!.isFinite) ? width! : 60.0);
    return (base * .35).clamp(18.0, 40.0).toDouble();
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        color: AppColors.alice,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.bell))
            : Icon(Icons.image_not_supported_outlined,
                color: AppColors.sky, size: _iconSize),
      );

  @override
  Widget build(BuildContext context) {
    var u = url.trim();
    if (u.startsWith('http://')) u = u.replaceFirst('http://', 'https://');

    Widget img;
    if (u.isEmpty) {
      img = _placeholder();
    } else if (u.startsWith('data:')) {
      img = Image.memory(
        base64Decode(u.split(',').last),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      img = Image.network(
        u,
        width: width,
        height: height,
        fit: fit,
        // Butuh Flutter 3.22+. Kalau error di baris ini, hapus 1 baris ini
        // atau jalankan: flutter upgrade
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(loading: true),
        errorBuilder: (_, e, __) {
          debugPrint('GAGAL MUAT FOTO: $u -> $e');
          return _placeholder();
        },
      );
    }
    return radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: img)
        : img;
  }
}