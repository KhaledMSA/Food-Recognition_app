// screens/prediction_result_screen.dart
//
// Shows the AnalysisPreview returned by POST /analyze-image.
// The user can:
//   • See predicted label + confidence
//   • See low-confidence warning if applicable
//   • Pick a different label from top-5
//   • Adjust serving quantity and unit
//   • Select meal type
//   • Tap "Confirm & Save" → POST /meals/from-analysis

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/prediction_result.dart';
import '../providers/meal_provider.dart';
import '../widgets/nutrition_card.dart';

class PredictionResultScreen extends StatefulWidget {
  final AnalysisPreview preview;
  final File            imageFile;
  final double          servingQuantity;
  final String          servingUnit;
  final int             userId;

  const PredictionResultScreen({
    super.key,
    required this.preview,
    required this.imageFile,
    required this.servingQuantity,
    required this.servingUnit,
    required this.userId,
  });

  @override
  State<PredictionResultScreen> createState() =>
      _PredictionResultScreenState();
}

class _PredictionResultScreenState
    extends State<PredictionResultScreen> {
  late final TextEditingController _qtyController;
  late String _selectedUnit;
  late String _confirmedLabel;
  String _mealType = 'meal';
  bool _showAllPredictions = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: widget.servingQuantity.toString());
    _selectedUnit   = widget.servingUnit;
    _confirmedLabel = widget.preview.predictedLabel;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _confirmSave() async {
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid serving quantity.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error    = null;
    });

    // Use confirmed label only if different from prediction
    final String? overrideLabel =
        _confirmedLabel != widget.preview.predictedLabel
            ? _confirmedLabel
            : null;

    final saved = await context.read<MealProvider>().confirmAndSaveMeal(
          userId:          widget.userId,
          preview:         widget.preview,
          servingQuantity: qty,
          servingUnit:     _selectedUnit,
          mealType:        _mealType,
          confirmedLabel:  overrideLabel,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${saved.foodName} saved to ${saved.mealTypeLabel}! ✅'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Pop back to upload screen (which pops back to dashboard)
      Navigator.pop(context);
    } else {
      final err = context.read<MealProvider>().errorMessage;
      setState(() => _error = err ?? 'Failed to save meal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Prediction Result',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Food image ──────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  widget.imageFile,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // ── Prediction card ─────────────────────────────────────────
              _PredictionCard(
                foodName:       p.foodName,
                confidence:     p.confidence,
                lowConfidence:  p.lowConfidenceWarning,
                processingMs:   p.processingTimeMs,
              ),
              const SizedBox(height: 14),

              // ── Nutrition preview ───────────────────────────────────────
              MacroRow(
                calories: p.calories,
                protein:  p.proteinG,
                carbs:    p.carbsG,
                fat:      p.fatG,
              ),

              // ── Nutrition note ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 16),
                child: Text(
                  'Estimated for ${p.servingQuantity.toStringAsFixed(0)} '
                  '${p.servingUnit} (${p.servingG.toStringAsFixed(0)} g)',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),

              // ── Top-5 alternatives ──────────────────────────────────────
              _Top5Section(
                predictions:    p.topPredictions,
                confirmedLabel: _confirmedLabel,
                expanded:       _showAllPredictions,
                onToggle: () => setState(
                    () => _showAllPredictions = !_showAllPredictions),
                onSelect: (label) =>
                    setState(() => _confirmedLabel = label),
              ),
              const SizedBox(height: 20),

              // ── Adjust serving ──────────────────────────────────────────
              const Text(
                'Adjust serving',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
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
              const SizedBox(height: 16),

              // ── Meal type ───────────────────────────────────────────────
              const Text(
                'Meal type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _MealTypeSelector(
                selected: _mealType,
                onChanged: (t) => setState(() => _mealType = t),
              ),
              const SizedBox(height: 20),

              // ── Error ───────────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Confirm button ──────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _confirmSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Confirm & Save Meal',
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
                      const Color(0xFF4CAF50).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 30),
            ],
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PredictionCard extends StatelessWidget {
  final String foodName;
  final double confidence;
  final bool   lowConfidence;
  final double processingMs;

  const _PredictionCard({
    required this.foodName,
    required this.confidence,
    required this.lowConfidence,
    required this.processingMs,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  foodName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: lowConfidence
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lowConfidence
                        ? Colors.orange.shade300
                        : Colors.green.shade300,
                  ),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: lowConfidence
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (lowConfidence) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Low confidence — check the top alternatives below.',
                      style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Processed in ${processingMs.toStringAsFixed(0)} ms',
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _Top5Section extends StatelessWidget {
  final List<PredictionItem> predictions;
  final String               confirmedLabel;
  final bool                 expanded;
  final VoidCallback         onToggle;
  final void Function(String) onSelect;

  const _Top5Section({
    required this.predictions,
    required this.confirmedLabel,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? predictions : predictions.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top predictions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            TextButton(
              onPressed: onToggle,
              child: Text(expanded ? 'Show less' : 'Show all 5'),
            ),
          ],
        ),
        ...visible.map((p) {
          final isSelected = p.className == confirmedLabel;
          return GestureDetector(
            onTap: () => onSelect(p.className),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 18)
                  else
                    Icon(Icons.circle_outlined,
                        color: Colors.grey.shade400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.className.replaceAll('_', ' '),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${(p.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _MealTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _types = [
    ('breakfast', Icons.wb_sunny_rounded,    Colors.orange),
    ('lunch',     Icons.wb_cloudy_rounded,   Colors.green),
    ('dinner',    Icons.nights_stay_rounded, Colors.indigo),
    ('snack',     Icons.local_cafe_rounded,  Colors.purple),
    ('meal',      Icons.restaurant_rounded,  Colors.blueGrey),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map(((String t, IconData ic, Color c) record) {
        final (t, ic, c) = record;
        final isSelected = selected == t;
        return GestureDetector(
          onTap: () => onChanged(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? c.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? c : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ic,
                    size: 16,
                    color: isSelected ? c : Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  t[0].toUpperCase() + t.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? c : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
