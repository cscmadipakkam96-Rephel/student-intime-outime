import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _enrolController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _enrolController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final comnEnrolNo = _enrolController.text.trim();
    final password = _passwordController.text;

    if (comnEnrolNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your enrollment number and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        comnEnrolNo: comnEnrolNo,
        password: password,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200 && result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              studentName: user['name'] as String,
              comnEnrolNo: user['comn_enrol_no'] as String,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reach server: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4E),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to mark your daily check-in.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _enrolController,
                      decoration: InputDecoration(
                        hintText: 'Enrollment Number',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Date of Birth (DDMMYYYY)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D1B4E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
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
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Login',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
