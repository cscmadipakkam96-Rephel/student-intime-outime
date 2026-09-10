import 'package:flutter/material.dart';
import 'login_page.dart';
import 'batches_page.dart';
import 'class_attendance_page.dart';
import 'leave_requests_page.dart';
import '../services/api_service.dart';

class ProfilePage extends StatelessWidget {
  final String studentName;
  final String comnEnrolNo;

  const ProfilePage({
    super.key,
    required this.studentName,
    required this.comnEnrolNo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D1B4E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  studentName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              _infoTile(
                icon: Icons.badge_outlined,
                label: 'Enrollment Number',
                value: comnEnrolNo,
              ),
              const SizedBox(height: 24),
              _navTile(
                context,
                icon: Icons.groups_outlined,
                label: 'My Batches',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BatchesPage()),
                ),
              ),
              _navTile(
                context,
                icon: Icons.fact_check_outlined,
                label: 'My Attendance',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ClassAttendancePage()),
                ),
              ),
              _navTile(
                context,
                icon: Icons.assignment_outlined,
                label: 'My Leave Requests',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LeaveRequestsPage()),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9534F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await ApiService.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: const Color(0xFF2D1B4E)),
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2D1B4E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
