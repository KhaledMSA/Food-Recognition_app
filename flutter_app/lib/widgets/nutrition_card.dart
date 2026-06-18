import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final IconData icon;

  const NutritionCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            unit,
            style:
                TextStyle(fontSize: 11, color: color.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Row of 4 macro cards ────────────────────────────────────────────────────

class MacroRow extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MacroRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NutritionCard(
            label: 'Calories',
            value: calories,
            unit: 'kcal',
            color: const Color(0xFFFF6B35),
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NutritionCard(
            label: 'Protein',
            value: protein,
            unit: 'g',
            color: const Color(0xFF4CAF50),
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NutritionCard(
            label: 'Carbs',
            value: carbs,
            unit: 'g',
            color: const Color(0xFF2196F3),
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NutritionCard(
            label: 'Fat',
            value: fat,
            unit: 'g',
            color: const Color(0xFFFF9800),
            icon: Icons.opacity_rounded,
          ),
        ),
      ],
    );
  }
}
