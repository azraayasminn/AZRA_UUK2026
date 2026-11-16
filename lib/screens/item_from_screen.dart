import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'common.dart';
import 'net_image.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;
  const ItemFormScreen({super.key, this.item});
  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _code = TextEditingController(text: widget.item?.code);
  late final _image = TextEditingController(text: widget.item?.image);
  late final _spec = TextEditingController(text: widget.item?.spec);
  late String _category = kCategories.contains(widget.item?.category)
      ? widget.item!.category
      : kCategories.first;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final code = _code.text.trim().toUpperCase();
      if (await FirestoreService.codeExists(code, excludeId: widget.item?.id)) {
        _snack('Kode $code sudah dipakai alat lain');
        return;
      }
      // status TIDAK ikut disimpan di sini; status diatur oleh sistem peminjaman
      final data = {
        'item_name': _name.text.trim(),
        'category': _category,
        'code': code,
        'image': _image.text.trim().isEmpty
            ? 'https://picsum.photos/seed/$code/600/400'
            : _image.text.trim(),
        'spesification': _spec.text.trim(),
      };
      if (_isEdit) {
        await FirestoreService.updateItem(widget.item!.id, data);
      } else {
        await FirestoreService.addItem(data);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _image.dispose();
    _spec.dispose();
    super.dispose();
  }

  Widget _gap(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: w);
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(_isEdit ? 'Edit Alat' : 'Tambah Alat'),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: softShadow),
            child: Form(
              key: _form,
              child: Column(children: [
                // pratinjau gambar (ikut berubah saat URL diketik)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: AppColors.alice,
                    child: _image.text.trim().isEmpty
                        ? const Icon(Icons.image_outlined,
                            size: 48, color: AppColors.sky)
                        : NetImage(_image.text,
                            width: double.infinity, height: 150),
                  ),
                ),
                const SizedBox(height: 16),
                _gap(TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                        labelText: 'Nama Alat',
                        prefixIcon:
                            Icon(Icons.label_outline, color: AppColors.bell)),
                    validator: _req)),
                _gap(TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Kode (harus unik)',
                        prefixIcon: Icon(Icons.qr_code, color: AppColors.bell)),
                    validator: _req)),
                _gap(DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon:
                          Icon(Icons.category_outlined, color: AppColors.bell)),
                  items: kCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                )),
                _gap(TextFormField(
                    controller: _image,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'URL Gambar (opsional)',
                        prefixIcon:
                            Icon(Icons.image_outlined, color: AppColors.bell)))),
                _gap(TextFormField(
                    controller: _spec,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Spesifikasi'),
                    validator: _req)),
                if (_isEdit)
                  _gap(Row(children: [
                    const Text('Status saat ini: ',
                        style: TextStyle(color: AppColors.muted)),
                    StatusBadge(widget.item!.status),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Text('(diatur otomatis oleh peminjaman)',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.muted))),
                  ])),
                GradientButton(
                    text: 'Simpan',
                    loading: _saving,
                    onPressed: _saving ? null : _save),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}