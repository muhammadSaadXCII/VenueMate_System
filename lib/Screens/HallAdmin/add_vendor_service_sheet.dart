import 'package:flutter/material.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

/// Used in two places:
///   1. HallRegistrationScreen Step 4 — collects items locally
///   2. ManageServicesScreen — saves directly to Firestore
///
/// Pass [existing] to pre-fill for editing.
/// [onSave] returns a Map<String, String> with keys:
///   name, description, price
class AddServiceSheet extends StatefulWidget {
  final Map<String, String>? existing;
  final void Function(Map<String, String> item) onSave;

  const AddServiceSheet({super.key, this.existing, required this.onSave});

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _nameController.text = e['name'] ?? '';
      _descController.text = e['description'] ?? '';
      _priceController.text = e['price'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final description = _descController.text.trim();

    if (name.isEmpty) {
      _snack('Service Name is required.');
      return;
    }
    if (name.length < 3) {
      _snack('Please enter a valid service.');
      return;
    }
    if (description.isEmpty) {
      _snack('Service Description is required.');
      return;
    }
    if (description.length < 10) {
      _snack('Service description must be at least 10 characters.');
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

    setState(() => _isSaving = true);

    widget.onSave({
      'name': name,
      'description': _descController.text.trim(),
      'price': price,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                _isEditing ? 'Edit Service' : 'Add New Service',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Service Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDec('Enter Service Name'),
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
                decoration: _inputDec('Enter Service Description'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Price (Rs.)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDec('Enter Price'),
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
