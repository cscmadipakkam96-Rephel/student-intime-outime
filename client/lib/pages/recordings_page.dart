import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'video_player_page.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _recordings = [];

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
      final result = await ApiService.getMyRecordings();
      if (result['statusCode'] == 200 && result['success'] == true) {
        setState(() {
          _recordings = (result['recordings'] as List).cast<Map<String, dynamic>>();
        });
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Failed to load recordings');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VideoPlayerPage(url: url, title: title)),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
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
                  'My Class Recordings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    if (_recordings.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(
            child: Text(
              'No recordings yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final r = _recordings[index];
        final filename = r['filename'] as String? ?? 'Recording';
        final url = r['url'] as String?;
        final date = _formatDate(r['lastModified'] as String?);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E0F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_fill, color: Color(0xFF2D1B4E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              if (url != null)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF2D1B4E)),
                  onPressed: () => _play(url, filename),
                ),
            ],
          ),
        );
      },
    );
  }
}
