// screens/onboarding_screen.dart
//
// 6-step onboarding flow after signup. Uses a PageView.
// Steps: Name → Goal → Gender → Weight → Height → Weekly Effort

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form values
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _goal;
  String? _gender;
  String? _weeklyEffort;

  // Validation errors per step
  String? _stepError;

  @override
  void initState() {
    super.initState();
    // Pre-fill name if already provided during signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.name != null && user!.name!.isNotEmpty) {
        _nameCtrl.text = user.name!;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) {
          setState(() => _stepError = 'Please enter your name.');
          return false;
        }
      case 1:
        if (_goal == null) {
          setState(() => _stepError = 'Please select a goal.');
          return false;
        }
      case 2:
        if (_gender == null) {
          setState(() => _stepError = 'Please select your gender.');
          return false;
        }
      case 3:
        final w = double.tryParse(_weightCtrl.text.trim());
        if (w == null || w <= 0) {
          setState(() => _stepError = 'Enter a valid weight.');
          return false;
        }
      case 4:
        final h = double.tryParse(_heightCtrl.text.trim());
        if (h == null || h <= 0) {
          setState(() => _stepError = 'Enter a valid height.');
          return false;
        }
      case 5:
        if (_weeklyEffort == null) {
          setState(() => _stepError = 'Please select your activity level.');
          return false;
        }
    }
    setState(() => _stepError = null);
    return true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.completeOnboarding(
      name: _nameCtrl.text.trim(),
      goal: _goal!,
      gender: _gender!,
      weightKg: double.parse(_weightCtrl.text.trim()),
      heightCm: double.parse(_heightCtrl.text.trim()),
      weeklyEffort: _weeklyEffort!,
    );

    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentPage + 1} of 6',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${((_currentPage + 1) / 6 * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF43A047)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _NamePage(controller: _nameCtrl),
                  _GoalPage(
                    selected: _goal,
                    onSelected: (v) => setState(() => _goal = v),
                  ),
                  _GenderPage(
                    selected: _gender,
                    onSelected: (v) => setState(() => _gender = v),
                  ),
                  _WeightPage(controller: _weightCtrl),
                  _HeightPage(controller: _heightCtrl),
                  _EffortPage(
                    selected: _weeklyEffort,
                    onSelected: (v) => setState(() => _weeklyEffort = v),
                  ),
                ],
              ),
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (_stepError != null || auth.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _stepError ?? auth.errorMessage!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ),

            // ── Navigation buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => _stepError = null);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF43A047)),
                          foregroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _currentPage == 5 ? 'Finish 🎉' : 'Next',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step pages ───────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      icon: Icons.badge_outlined,
      title: "What's your name?",
      subtitle: 'This is how we\'ll greet you on the dashboard.',
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Full Name'),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  const _GoalPage({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        'lose_weight',
        'Lose Weight',
        Icons.trending_down_rounded,
        'Reduce body fat'
      ),
      (
        'maintain_weight',
        'Maintain Weight',
        Icons.balance_rounded,
        'Keep current weight'
      ),
      (
        'gain_weight',
        'Gain Weight',
        Icons.trending_up_rounded,
        'Add healthy mass'
      ),
      (
        'build_muscle',
        'Build Muscle',
        Icons.fitness_center_rounded,
        'Increase muscle mass'
      ),
    ];

    return _StepWrapper(
      icon: Icons.flag_outlined,
      title: 'What is your goal?',
      subtitle: 'We\'ll calculate your daily nutrition targets.',
      child: Column(
        children: options
            .map((o) => _OptionCard(
                  value: o.$1,
                  label: o.$2,
                  icon: o.$3,
                  subtitle: o.$4,
                  selected: selected == o.$1,
                  onTap: () => onSelected(o.$1),
                ))
            .toList(),
      ),
    );
  }
}

class _GenderPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  const _GenderPage({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('male', 'Male', Icons.male_rounded),
      ('female', 'Female', Icons.female_rounded),
      ('other', 'Other', Icons.person_outline_rounded),
    ];

    return _StepWrapper(
      icon: Icons.wc_rounded,
      title: 'What is your gender?',
      subtitle: 'Used to estimate your base calorie needs.',
      child: Column(
        children: options
            .map((o) => _OptionCard(
                  value: o.$1,
                  label: o.$2,
                  icon: o.$3,
                  selected: selected == o.$1,
                  onTap: () => onSelected(o.$1),
                ))
            .toList(),
      ),
    );
  }
}

class _WeightPage extends StatelessWidget {
  final TextEditingController controller;
  const _WeightPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      icon: Icons.monitor_weight_outlined,
      title: 'What is your weight?',
      subtitle: 'Enter your current weight in kilograms.',
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Weight',
          suffixText: 'kg',
        ),
      ),
    );
  }
}

class _HeightPage extends StatelessWidget {
  final TextEditingController controller;
  const _HeightPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepWrapper(
      icon: Icons.height_rounded,
      title: 'What is your height?',
      subtitle: 'Enter your height in centimeters.',
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Height',
          suffixText: 'cm',
        ),
      ),
    );
  }
}

class _EffortPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  const _EffortPage({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('low', 'Low', Icons.self_improvement_rounded, 'Little or no exercise'),
      (
        'moderate',
        'Moderate',
        Icons.directions_walk_rounded,
        'Exercise 2–3× per week'
      ),
      (
        'high',
        'High',
        Icons.directions_run_rounded,
        'Exercise 5+ times per week'
      ),
    ];

    return _StepWrapper(
      icon: Icons.fitness_center_rounded,
      title: 'How active are you?',
      subtitle: 'Your weekly exercise level affects calorie targets.',
      child: Column(
        children: options
            .map((o) => _OptionCard(
                  value: o.$1,
                  label: o.$2,
                  icon: o.$3,
                  subtitle: o.$4,
                  selected: selected == o.$1,
                  onTap: () => onSelected(o.$1),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 30),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.value,
    required this.label,
    required this.icon,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF43A047).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF43A047) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF43A047).withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? const Color(0xFF2E7D32) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color:
                            selected ? const Color(0xFF1B5E20) : Colors.black87,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF43A047), size: 22),
          ],
        ),
      ),
    );
  }
}
