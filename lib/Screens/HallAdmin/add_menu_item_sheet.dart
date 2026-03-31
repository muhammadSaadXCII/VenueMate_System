import 'dart:io';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

/// Used in two places:
///   1. HallRegistrationScreen Step 4 — collects items locally
///   2. ManageMenuScreen — saves directly to Firestore
///
/// Changes from original:
///   - Image upload is now MANDATORY (cannot Add without an image)
///   - Image preview uses Image.file() — shows immediately after picking
///   - Red border + "Required" label shown when user tries to Add without image
class AddMenuItemSheet extends StatefulWidget {
  final Map<String, String>? existing;
  final void Function(Map<String, String> item) onSave;

  const AddMenuItemSheet({super.key, this.existing, required this.onSave});

  @override
  State<AddMenuItemSheet> createState() => _AddMenuItemSheetState();
}

class _AddMenuItemSheetState extends State<AddMenuItemSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedUnit = '/Serving';
  File? _imageFile;
  bool _isSaving = false;
  bool _imageRequired = false; // turns true after a failed save attempt

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
      _selectedUnit =
          e['priceUnit'] != null ? '/${e['priceUnit']}' : '/Serving';
      // If editing and there was a previously picked local path, don't pre-load
      // the file (we don't have it in memory). Treat image as optional for edits.
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
    final file = await StorageService.pickImageFromGallery();
    if (file != null && mounted) {
      setState(() {
        _imageFile = file;
        _imageRequired = false; // clear the error once image is picked
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();

    // ── Validation ──────────────────────────────────────────────────────────
    if (name.isEmpty) {
      _snack('Please enter item name.');
      return;
    }
    if (price.isEmpty || double.tryParse(price) == null) {
      _snack('Please enter a valid price.');
      return;
    }
    // Image is mandatory for new items (not editing)
    if (!_isEditing && _imageFile == null) {
      setState(() => _imageRequired = true);
      _snack('Please upload an image for this item.');
      return;
    }

    setState(() => _isSaving = true);

    widget.onSave({
      'name': name,
      'description': _descController.text.trim(),
      'price': price,
      'priceUnit': _selectedUnit.replaceFirst('/', ''), // 'Serving'
      'imageUrl': _imageFile?.path ?? '', // local file path
    });

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
              // Handle bar
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
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // ── Image picker + Name row ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
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
                              // Red border when image is required but missing
                              color:
                                  _imageRequired
                                      ? Colors.red
                                      : _imageFile != null
                                      ? const Color(0xFFF47C20)
                                      : Colors.grey[400]!,
                              width:
                                  (_imageRequired || _imageFile != null)
                                      ? 2
                                      : 1,
                            ),
                          ),
                          child:
                              _imageFile != null
                                  // ✅ Image.file — shows the local picked image
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 32,
                                        color:
                                            _imageRequired
                                                ? Colors.red
                                                : Colors.black54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to upload\nPhoto*',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _imageRequired
                                                  ? Colors.red
                                                  : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      // "Required" label below image box
                      if (_imageRequired)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Image required',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Item Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDec('Enter Item Name'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDec("Enter Menu Item's Description"),
              ),
              const SizedBox(height: 16),

              // ── Price + Unit ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(text: 'Price '),
                              TextSpan(
                                text: '(Rs.)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('Enter Price'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          decoration: _inputDec(''),
                          items:
                              _units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ],
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
