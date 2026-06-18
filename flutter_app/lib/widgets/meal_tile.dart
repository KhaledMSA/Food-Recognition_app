// widgets/meal_tile.dart
//
// A single row in the meal list. Shows food name, serving, time,
// calories, and a delete button.

import 'package:flutter/material.dart';
import '../models/meal.dart';

class MealTile extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback? onDelete;

  const MealTile({
    super.key,
    required this.meal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: _FoodIcon(label: meal.foodName),
        title: Text(
          meal.foodName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              _Tag(
                label: meal.mealTypeLabel,
                color: _mealTypeColor(meal.mealType),
              ),
              const SizedBox(width: 6),
              Text(
                '${meal.servingQuantity.toStringAsFixed(0)} ${meal.servingUnit}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              Text(
                meal.formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  meal.calories.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete meal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _mealTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'breakfast' => const Color(0xFFFF9800),
      'lunch' => const Color(0xFF4CAF50),
      'dinner' => const Color(0xFF3F51B5),
      'snack' => const Color(0xFF9C27B0),
      _ => const Color(0xFF607D8B),
    };
  }
}

class _FoodIcon extends StatelessWidget {
  final String label;
  const _FoodIcon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
