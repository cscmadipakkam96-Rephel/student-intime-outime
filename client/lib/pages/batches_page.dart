import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'leave_request_form_page.dart';

class BatchesPage extends StatefulWidget {
  const BatchesPage({super.key});

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

class _BatchesPageState extends State<BatchesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _batches = [];

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
      final result = await ApiService.getBatches();
      if (result['statusCode'] == 200 && result['success'] == true) {
        setState(() => _batches = (result['data'] as List).cast<Map<String, dynamic>>());
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Failed to load batches');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _requestLeave(Map<String, dynamic> batch) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaveRequestFormPage(
          batchId: batch['batch_id'] as int,
          batchName: batch['batch_name'] as String,
          subjectName: batch['subject_name'] as String?,
          leaveType: 'advance',
        ),
      ),
    );
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
                  'My Batches',
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
    if (_batches.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(child: Text('No batches enrolled yet', style: TextStyle(color: Colors.grey))),
        ],
      );
    }

    return ListView.builder(
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final b = _batches[index];
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b['subject_name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E0F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b['batch_name'] as String? ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2D1B4E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                b['section_label'] as String? ?? '',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(b['timing'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(b['teacher_name'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D1B4E),
                    side: const BorderSide(color: Color(0xFF2D1B4E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _requestLeave(b),
                  icon: const Icon(Icons.event_busy, size: 18),
                  label: const Text('Request Leave'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
