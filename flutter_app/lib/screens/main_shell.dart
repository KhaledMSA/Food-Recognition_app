// screens/main_shell.dart
//
// Bottom navigation shell with 5 tabs:
//   0 = Dashboard
//   1 = Scan  (full-screen push, not a tab)
//   2 = Diary
//   3 = History
//   4 = Profile

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import 'dashboard_screen.dart';
import 'diary_screen.dart';
import 'meal_history_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;

  // The 4 persistent screens (Scan handled as push)
  static const List<Widget> _screens = [
    DashboardScreen(),
    DiaryScreen(),
    MealHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId > 0) {
        context.read<MealProvider>().loadTodayData(userId);
      }
    });
  }

  /// Maps bottom-nav tab index → IndexedStack index.
  /// Tabs: 0=Dashboard, 1=Scan(push), 2=Diary, 3=History, 4=Profile
  /// Stack: 0=Dashboard,              1=Diary,  2=History, 3=Profile
  int get _stackIndex {
    if (_selectedIndex <= 1) return 0;
    return _selectedIndex - 1;
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Scan — push full screen
      final userId = context.read<AuthProvider>().userId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadScreen(userId: userId),
        ),
      ).then((_) {
        if (!mounted) return;
        final uid = context.read<AuthProvider>().userId;
        if (uid > 0) context.read<MealProvider>().loadTodayData(uid);
      });
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 1 ? 0 : _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note_rounded),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
