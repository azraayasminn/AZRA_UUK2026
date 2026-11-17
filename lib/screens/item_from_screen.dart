
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

  late final _name = TextEditingController(
    text: widget.item?.name ?? '',
  );

  late final _code = TextEditingController(
    text: widget.item?.code ?? '',
  );

  late final _image = TextEditingController(
    text: widget.item?.image ?? '',
  );

  late final _spec = TextEditingController(
    text: widget.item?.spec ?? '',
  );

  late String _category = kCategories.contains(widget.item?.category)
      ? widget.item!.category
      : kCategories.first;

  bool _saving = false;

  bool get _isEdit => widget.item != null;

  // ================= SNACKBAR =================

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ================= SIMPAN DATA =================

  Future<void> _save() async {
    if (_saving) return;

    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final code = _code.text.trim().toUpperCase();

      // Validasi kode barang agar tidak duplikat.
      if (await FirestoreService.codeExists(
        code,
        excludeId: widget.item?.id,
      )) {
        _snack('Kode $code sudah dipakai alat lain');
        return;
      }

      // Status tidak disimpan di sini.
      // Status diatur otomatis oleh sistem peminjaman.
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
        await FirestoreService.updateItem(
          widget.item!.id,
          data,
        );
      } else {
        await FirestoreService.addItem(data);
      }

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {
      _snack(
        'Gagal menyimpan: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _image.dispose();
    _spec.dispose();

    super.dispose();
  }

  // ================= WIDGET BANTUAN =================

  Widget _gap(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: child,
    );
  }

  String? _req(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }

    return null;
  }

  // ================= TOMBOL BATAL =================

  Widget _cancelButton() {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pale,
            foregroundColor: AppColors.deep,
            disabledBackgroundColor: AppColors.pale,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ================= TOMBOL SIMPAN =================

  Widget _saveButton() {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: headerGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(
        _isEdit ? 'Edit Alat' : 'Tambah Alat',
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow,
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ================= PREVIEW GAMBAR =================

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: AppColors.alice,
                      child: _image.text.trim().isEmpty
                          ? const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: AppColors.sky,
                            )
                          : NetImage(
                              _image.text.trim(),
                              width: double.infinity,
                              height: 150,
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= NAMA ALAT =================

                  _gap(
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nama Alat',
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: AppColors.bell,
                        ),
                      ),
                      validator: _req,
                    ),
                  ),

                  // ================= KODE ALAT =================

                  _gap(
                    TextFormField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Kode (harus unik)',
                        prefixIcon: Icon(
                          Icons.qr_code,
                          color: AppColors.bell,
                        ),
                      ),
                      validator: _req,
                    ),
                  ),

                  // ================= KATEGORI =================

                  _gap(
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.bell,
                        ),
                      ),
                      items: kCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
                    ),
                  ),

                  // ================= URL GAMBAR =================

                  _gap(
                    TextFormField(
                      controller: _image,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar (opsional)',
                        prefixIcon: Icon(
                          Icons.image_outlined,
                          color: AppColors.bell,
                        ),
                      ),
                    ),
                  ),

                  // ================= SPESIFIKASI =================

                  _gap(
                    TextFormField(
                      controller: _spec,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Spesifikasi',
                      ),
                      validator: _req,
                    ),
                  ),

                  // ================= STATUS BARANG =================

                  if (_isEdit)
                    _gap(
                      Row(
                        children: [
                          const Text(
                            'Status saat ini: ',
                            style: TextStyle(
                              color: AppColors.muted,
                            ),
                          ),
                          StatusBadge(widget.item!.status),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '(diatur otomatis oleh peminjaman)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ================= TOMBOL BATAL & SIMPAN =================

                  Row(
                    children: [
                      _cancelButton(),
                      const SizedBox(width: 10),
                      _saveButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
