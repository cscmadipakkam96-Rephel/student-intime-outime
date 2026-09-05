import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'recordings_page.dart';
import 'course_videos_page.dart';

class MainScreen extends StatefulWidget {
  final String studentName;
  final String comnEnrolNo;

  const MainScreen({
    super.key,
    required this.studentName,
    required this.comnEnrolNo,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(studentName: widget.studentName),
      const RecordingsPage(),
      const CourseVideosPage(),
      ProfilePage(
        studentName: widget.studentName,
        comnEnrolNo: widget.comnEnrolNo,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2D1B4E),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Recordings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Courses',
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
