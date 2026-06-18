// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  // Edit controllers
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _editGoal;
  String? _editEffort;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _startEdit(UserModel user) {
    _weightCtrl.text = user.weightKg?.toString() ?? '';
    _heightCtrl.text = user.heightCm?.toString() ?? '';
    _editGoal = user.goal;
    _editEffort = user.weeklyEffort;
    setState(() => _editing = true);
  }

  Future<void> _saveEdit() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      goal: _editGoal,
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      heightCm: double.tryParse(_heightCtrl.text.trim()),
      weeklyEffort: _editEffort,
    );
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content:
            const Text('You will need to log in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => _startEdit(user),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32)),
            ),
          if (_editing)
            TextButton(
              onPressed: _saveEdit,
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Avatar + name ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user.name?.isNotEmpty == true)
                            ? user.name![0].toUpperCase()
                            : user.email[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Goal card ─────────────────────────────────────────────────
            _ProfileCard(
              title: 'My Goal',
              icon: Icons.flag_rounded,
              child: _editing
                  ? _GoalDropdown(
                      value: _editGoal,
                      onChanged: (v) => setState(() => _editGoal = v),
                    )
                  : Text(user.goalLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),

            // ── Physical stats ────────────────────────────────────────────
            _ProfileCard(
              title: 'Physical Stats',
              icon: Icons.monitor_weight_outlined,
              child: Column(
                children: [
                  _editing
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _heightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Height (cm)',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Weight',
                                value: user.weightKg != null
                                    ? '${user.weightKg!.toStringAsFixed(1)} kg'
                                    : '—',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatBox(
                                label: 'Height',
                                value: user.heightCm != null
                                    ? '${user.heightCm!.toStringAsFixed(0)} cm'
                                    : '—',
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Gender',
                          value: user.genderLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _editing
                            ? _EffortDropdown(
                                value: _editEffort,
                                onChanged: (v) =>
                                    setState(() => _editEffort = v),
                              )
                            : _StatBox(
                                label: 'Activity',
                                value: user.effortLabel,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Daily targets ─────────────────────────────────────────────
            _ProfileCard(
              title: 'Daily Nutrition Targets',
              icon: Icons.pie_chart_outline_rounded,
              child: Column(
                children: [
                  _TargetRow(
                      label: 'Calories',
                      value: '${user.dailyCalorieGoal} kcal',
                      color: const Color(0xFF43A047)),
                  _TargetRow(
                      label: 'Protein',
                      value: '${user.dailyProteinGoal} g',
                      color: const Color(0xFF1565C0)),
                  _TargetRow(
                      label: 'Carbs',
                      value: '${user.dailyCarbsGoal} g',
                      color: const Color(0xFFE65100)),
                  _TargetRow(
                      label: 'Fat',
                      value: '${user.dailyFatGoal} g',
                      color: const Color(0xFF6A1B9A),
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Logout ────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF43A047)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _TargetRow({
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(label,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GoalDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GoalDropdown({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Goal', isDense: true),
      items: const [
        DropdownMenuItem(value: 'lose_weight', child: Text('Lose Weight')),
        DropdownMenuItem(
            value: 'maintain_weight', child: Text('Maintain Weight')),
        DropdownMenuItem(value: 'gain_weight', child: Text('Gain Weight')),
        DropdownMenuItem(value: 'build_muscle', child: Text('Build Muscle')),
      ],
      onChanged: onChanged,
    );
  }
}

class _EffortDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _EffortDropdown({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Activity', isDense: true),
      items: const [
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
        DropdownMenuItem(value: 'high', child: Text('High')),
      ],
      onChanged: onChanged,
    );
  }
}
