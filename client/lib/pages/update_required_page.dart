import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// A dead-end screen — no back navigation, no way to reach login/dashboard
// from here. The only way out is actually updating and relaunching the app.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.cscitedu.stud';

  Future<void> _openPlayStore() async {
    await launchUrl(Uri.parse(_playStoreUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B4E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.system_update, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Update Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A new version of this app is available. Please update to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D1B4E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _openPlayStore,
                    child: const Text(
                      'Update Now',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
