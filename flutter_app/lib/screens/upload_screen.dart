// screens/upload_screen.dart
//
// Lets the user pick an image from the camera or gallery,
// set the serving quantity and unit, then calls POST /analyze-image.
// Navigates to PredictionResultScreen on success.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import 'prediction_result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File?   _selectedImage;
  bool    _isAnalyzing = false;
  String? _error;

  final _qtyController =
      TextEditingController(text: ApiConfig.defaultServingQty.toString());
  String _selectedUnit = ApiConfig.defaultServingUnit;

  final _picker  = ImagePicker();
  final _api     = ApiService();
  final _qtyFocus = FocusNode();

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _error = null;
    });
  }

  // ── Analyze ───────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid serving quantity (e.g. 100).');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final preview = await _api.analyzeImage(
        imageFile:       _selectedImage!,
        userId:          ApiConfig.userId,
        servingQuantity: qty,
        servingUnit:     _selectedUnit,
      );

      if (!mounted) return;

      // Navigate to result screen, which handles the confirm step
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            preview:         preview,
            imageFile:       _selectedImage!,
            servingQuantity: qty,
            servingUnit:     _selectedUnit,
          ),
        ),
      );

      // Pop back to dashboard after a successful save
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Scan Food',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image preview / picker area ───────────────────────────
                _ImagePickerArea(
                  image: _selectedImage,
                  onCamera:  () => _pick(ImageSource.camera),
                  onGallery: () => _pick(ImageSource.gallery),
                ),
                const SizedBox(height: 24),

                // ── Serving inputs ────────────────────────────────────────
                const Text(
                  'Serving size',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _qtyController,
                        focusNode: _qtyFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _inputDecoration('Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: _inputDecoration('Unit'),
                        items: ApiConfig.servingUnits
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Error message ─────────────────────────────────────────
                if (_error != null) ...[
                  _ErrorBox(message: _error!),
                  const SizedBox(height: 16),
                ],

                // ── Analyze button ────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    _isAnalyzing ? 'Analyzing...' : 'Analyze Image',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor:
                        const Color(0xFF4CAF50).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─── Image picker area ────────────────────────────────────────────────────────

class _ImagePickerArea extends StatelessWidget {
  final File? image;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImagePickerArea({
    required this.image,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview
        GestureDetector(
          onTap: onGallery,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: image != null
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(image!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to pick from gallery',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Camera + Gallery buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey,
                  side: BorderSide(color: Colors.blueGrey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
