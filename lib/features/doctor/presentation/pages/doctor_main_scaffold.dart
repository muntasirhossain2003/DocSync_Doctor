import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../consultations/presentation/pages/consultations_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class DoctorMainScaffold extends ConsumerStatefulWidget {
  const DoctorMainScaffold({super.key});

  @override
  ConsumerState<DoctorMainScaffold> createState() => _DoctorMainScaffoldState();
}

class _DoctorMainScaffoldState extends ConsumerState<DoctorMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ConsultationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call_outlined),
            activeIcon: Icon(Icons.video_call),
            label: 'Consultations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
