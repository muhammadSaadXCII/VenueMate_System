import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

/// Used in two places:
/// 1. HallRegistrationScreen Step 4 — collects items locally
/// 2. ManageMenuScreen — saves directly to Firestore
///
/// onSave returns both the Map<String,String> (for local display)
/// AND the XFile (for Firebase Storage upload).
class AddMenuItemSheet extends StatefulWidget {
  final Map<String, String>? existing;

  /// Called on save.
  /// [item] contains the text fields + imageUrl as a base64 data-URI.
  /// [xFile] is the picked image — null if no new image was picked.
  final void Function(Map<String, String> item, XFile? xFile) onSave;

  const AddMenuItemSheet({super.key, this.existing, required this.onSave});

  @override
  State<AddMenuItemSheet> createState() => _AddMenuItemSheetState();
}

class _AddMenuItemSheetState extends State<AddMenuItemSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedUnit = '/Serving';
  XFile? _pickedXFile;
  Uint8List? _imageBytes;

  bool _isSaving = false;
  bool _imageRequired = false;

  final List<String> _units = ['/Plate', '/Serving', '/Head', '/Pcs'];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _nameController.text = e['name'] ?? '';
      _descController.text = e['description'] ?? '';
      _priceController.text = e['price'] ?? '';
      // priceUnit stored as "Serving", dropdown values are "/Serving"
      _selectedUnit =
          e['priceUnit'] != null ? '/${e['priceUnit']}' : '/Serving';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xf = await StorageService.pickImageXFile();
    if (xf == null || !mounted) return;

    final bytes = await xf.readAsBytes();

    setState(() {
      _pickedXFile = xf;
      _imageBytes = bytes;
      _imageRequired = false;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();

    if (name.isEmpty) {
      _snack('Item Name is required.');
      return;
    }
    if (price.isEmpty) {
      _snack('Price is required.');
      return;
    }
    final priceInt = double.tryParse(price);
    if (priceInt == null || priceInt <= 0) {
      _snack('Please enter a valid price.');
      return;
    }
    // Image is mandatory for new items only
    if (!_isEditing && _pickedXFile == null) {
      setState(() => _imageRequired = true);
      _snack('Please upload an image for this item.');
      return;
    }

    setState(() => _isSaving = true);

    // ── Build imageUrl ──────────────────────────────────────────────────────
    // If a new image was picked, encode it as a base64 data-URI so that
    // MenuItemCard can display it on BOTH web and mobile without any network
    // call. MenuItemCard already handles the 'data:image' prefix correctly.
    //
    // If we're editing and no new image was picked, keep the existing URL
    // (could be a Firebase Storage https:// URL or a previous data-URI).
    final String imageUrl;
    if (_imageBytes != null) {
      final base64Str = base64Encode(_imageBytes!);
      imageUrl = 'data:image/jpeg;base64,$base64Str';
    } else {
      imageUrl = widget.existing?['imageUrl'] ?? '';
    }
    // ───────────────────────────────────────────────────────────────────────

    widget.onSave({
      'name': name,
      'description': _descController.text.trim(),
      'price': price,
      'priceUnit': _selectedUnit.replaceFirst('/', ''),
      'imageUrl': imageUrl, // ← was always '' before, now carries real data
    }, _pickedXFile);

    Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Colors.grey,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _isEditing ? 'Edit Menu Item' : 'Add New Menu Item',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Image picker + name field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _imageRequired
                                  ? Colors.red
                                  : _imageBytes != null
                                  ? const Color(0xFFF47C20)
                                  : Colors.grey,
                          width:
                              (_imageRequired || _imageBytes != null) ? 2 : 1,
                        ),
                      ),
                      child:
                          _imageBytes != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to upload\nPhoto*',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDec('Enter Item Name'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDec('Enter Description'),
              ),

              const SizedBox(height: 16),

              // Price + unit
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('Enter Price'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items:
                          _units
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              CommonButton(
                text: _isEditing ? 'Save Changes' : 'Add',
                onTap: _isSaving ? () {} : _save,
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }
}
