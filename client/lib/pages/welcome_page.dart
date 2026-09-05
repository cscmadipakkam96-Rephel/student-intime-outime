import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'update_required_page.dart';
import '../services/api_service.dart';

// Compares two "1.2.3"-style version strings. Returns true if [installed]
// is older than [required]. Missing/short segments are treated as 0
// (e.g. "1.2" vs "1.2.1").
bool _isOlderVersion(String installed, String required) {
  final a = installed.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final b = required.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // True while silently checking, right on app launch, whether a still-valid
  // session cookie (now good for 30 days) already exists — students should
  // land straight on the dashboard, not have to tap "Login" every time they
  // reopen the app.
  bool _autoChecking = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkPlayStoreUpdate();
    _checkVersionThenSession();
  }

  // Google Play's own update check — only fires if the app was installed via
  // Play Store and Play Store has a newer version live for the track this
  // install came from. Separate from, and in addition to, our own
  // MIN_APP_VERSION gate below. Runs fire-and-forget: failures (e.g. app not
  // installed from Play Store, no Play Store on device) are silently ignored.
  Future<void> _checkPlayStoreUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Not installed from Play Store, no update, or Play services
      // unavailable — nothing to do.
    }
  }

  // A blocked-version app must never reach the login/session check at all —
  // this runs first, and only continues into _checkExistingSession() if the
  // installed build is current.
  Future<void> _checkVersionThenSession() async {
    try {
      final versionResult = await ApiService.getMinAppVersion();
      final packageInfo = await PackageInfo.fromPlatform();

      if (versionResult['statusCode'] == 200 && versionResult['success'] == true) {
        final minVersion = versionResult['minVersion'] as String;
        if (_isOlderVersion(packageInfo.version, minVersion)) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UpdateRequiredPage()),
          );
          return;
        }
      }
    } catch (_) {
      // Version-check server unreachable — don't block the app over that;
      // fall through to the normal session check.
    }
    await _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final result = await ApiService.me();
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
        return;
      }
    } catch (_) {
      // Server unreachable or no cookie at all — fall through to showing
      // the welcome screen so the student can log in manually.
    }
    if (mounted) setState(() => _autoChecking = false);
  }

  Future<void> _handleLoginPress() async {
    setState(() => _checking = true);

    try {
      // Manual retry of the same check the button press triggers, for when
      // the automatic check above found no valid session.
      final result = await ApiService.me();

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
    if (_autoChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                'CSC',
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
