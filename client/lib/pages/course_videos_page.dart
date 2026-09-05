import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'video_player_page.dart';

class CourseVideosPage extends StatefulWidget {
  const CourseVideosPage({super.key});

  @override
  State<CourseVideosPage> createState() => _CourseVideosPageState();
}

class _CourseVideosPageState extends State<CourseVideosPage> {
  // Manager's WhatsApp number (with country code, no + or spaces) that
  // enroll requests are sent to.
  static const String _managerWhatsAppNumber = '917418214748';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getCourseVideos();
      if (result['statusCode'] == 200 && result['success'] == true) {
        setState(() {
          _videos = (result['videos'] as List).cast<Map<String, dynamic>>();
        });
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Failed to load course videos');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Opens WhatsApp with a pre-filled "I want to enroll for <course> (<price>)"
  // message addressed to the manager — enrollment/payment is arranged
  // manually over that chat, no in-app payment gateway involved.
  Future<void> _enrollViaWhatsApp(Map<String, dynamic> video) async {
    final title = video['title'] as String? ?? 'this course';
    final price = _formatPrice(video['price']);
    final message = 'I want to Enroll for $title ($price)';
    final uri = Uri.parse(
      'https://wa.me/$_managerWhatsAppNumber?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Future<void> _play(String id, String title) async {
    final result = await ApiService.getCourseVideoPlayUrl(id);
    if (result['statusCode'] == 200 && result['success'] == true) {
      final url = result['url'] as String;
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => VideoPlayerPage(url: url, title: title)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Could not load video')),
      );
    }
  }

  String _formatPrice(dynamic price) {
    final value = double.tryParse(price?.toString() ?? '');
    if (value == null) return '';
    return value == value.roundToDouble()
        ? '₹${value.toInt()}'
        : '₹${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Videos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enroll and watch premium course content',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ],
      );
    }
    if (_videos.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(child: Text('No course videos yet', style: TextStyle(color: Colors.grey))),
        ],
      );
    }

    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final id = video['id'] as String;
        final title = video['title'] as String? ?? 'Untitled';
        final durationMinutes = video['durationMinutes'];
        final unlocked = video['purchased'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unlocked ? const Color(0xFFE3F5EA) : const Color(0xFFF3E9E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.lock_open : Icons.lock_outline,
                  color: unlocked ? Colors.green : const Color(0xFF2D1B4E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      durationMinutes != null ? '$durationMinutes min' : 'Duration not available',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              unlocked
                  ? ElevatedButton.icon(
                      onPressed: () => _play(id, title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D1B4E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      label: const Text('Play', style: TextStyle(color: Colors.white)),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _enrollViaWhatsApp(video),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                      label: Text(
                        'Enroll ${_formatPrice(video['price'])}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
