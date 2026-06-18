// screens/diary_screen.dart
//
// Manual food logging form. POST /meals/manual

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _foodNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '100');
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbsCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');

  String _unit = 'g';
  String _mealType = 'meal';
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  static const _mealTypes = [
    ('breakfast', 'Breakfast'),
    ('lunch', 'Lunch'),
    ('dinner', 'Dinner'),
    ('snack', 'Snack'),
    ('meal', 'Other'),
  ];

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _qtyCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF43A047),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final userId = context.read<AuthProvider>().userId;
    final mealDate = _date.toIso8601String().substring(0, 10);

    final saved = await context.read<MealProvider>().saveManualMeal(
          userId: userId,
          foodName: _foodNameCtrl.text.trim(),
          servingQuantity: double.parse(_qtyCtrl.text.trim()),
          servingUnit: _unit,
          calories: double.tryParse(_caloriesCtrl.text.trim()) ?? 0,
          proteinG: double.tryParse(_proteinCtrl.text.trim()) ?? 0,
          carbsG: double.tryParse(_carbsCtrl.text.trim()) ?? 0,
          fatG: double.tryParse(_fatCtrl.text.trim()) ?? 0,
          mealType: _mealType,
          mealDate: mealDate,
        );

    if (mounted) {
      setState(() => _saving = false);
      if (saved != null) {
        _formKey.currentState!.reset();
        _foodNameCtrl.clear();
        _caloriesCtrl.clear();
        _proteinCtrl.text = '0';
        _carbsCtrl.text = '0';
        _fatCtrl.text = '0';
        _qtyCtrl.text = '100';
        setState(() {
          _date = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal logged successfully!'),
            backgroundColor: Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _error =
            context.read<MealProvider>().errorMessage ?? 'Failed to save');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Food Diary',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF43A047).withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Log a meal manually by entering\nthe food details below.',
                          style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Food Name ─────────────────────────────────────────────
                const _SectionLabel('Food Details'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _foodNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Food Name *',
                    prefixIcon: Icon(Icons.restaurant_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Food name is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // ── Serving ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: ApiConfig.servingUnits
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Nutrition ─────────────────────────────────────────────
                const _SectionLabel('Nutrition Info'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _caloriesCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal) *',
                    prefixIcon: Icon(Icons.local_fire_department_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MacroField(
                        label: 'Protein (g)',
                        controller: _proteinCtrl,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MacroField(
                        label: 'Carbs (g)',
                        controller: _carbsCtrl,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MacroField(
                        label: 'Fat (g)',
                        controller: _fatCtrl,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Meal type & date ──────────────────────────────────────
                const _SectionLabel('When'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _mealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  items: _mealTypes
                      .map((t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(t.$2),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _mealType = v!),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_date),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        const Text('Change',
                            style: TextStyle(
                                color: Color(0xFF43A047),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Error ─────────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Save button ───────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Meal',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final isToday = d.year == DateTime.now().year &&
        d.month == DateTime.now().month &&
        d.day == DateTime.now().day;
    return isToday ? 'Today' : '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;

  const _MacroField({
    required this.label,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}
