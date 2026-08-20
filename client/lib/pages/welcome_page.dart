import 'package:flutter/material.dart';
import 'login_page.dart';
import 'main_screen.dart';
import '../services/api_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _checking = false;

  Future<void> _handleLoginPress() async {
    setState(() => _checking = true);

    try {
      // Check whether a valid JWT is already sitting in the browser's
      // cookie jar from a previous session. If so, skip the login form
      // entirely and go straight to the dashboard.
      final result = await ApiService.me();

      if (!mounted) return;

      if (result['statusCode'] == 200 && result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              studentName: user['name'] as String,
              gmail: user['gmail'] as String? ?? '',
              comnEnrolNo: user['comn_enrol_no'] as String,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (_) {
      // Server unreachable or no cookie at all — fall back to the login form.
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D1B4E).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CSE Madipakkam',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Track your daily check-in and check-out\ntimings in one tap.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D1B4E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _checking ? null : _handleLoginPress,
                  child: _checking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
