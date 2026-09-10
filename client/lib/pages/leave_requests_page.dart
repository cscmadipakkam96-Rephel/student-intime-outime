import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaveRequestsPage extends StatefulWidget {
  const LeaveRequestsPage({super.key});

  @override
  State<LeaveRequestsPage> createState() => _LeaveRequestsPageState();
}

class _LeaveRequestsPageState extends State<LeaveRequestsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

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
      final result = await ApiService.getLeaveRequests();
      if (result['statusCode'] == 200 && result['success'] == true) {
        final rows = (result['data'] as List).cast<Map<String, dynamic>>();
        rows.sort((a, b) => (b['requested_at'] as String).compareTo(a['requested_at'] as String));
        setState(() => _requests = rows);
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Failed to load leave requests');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _displayDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
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
                  'My Leave Requests',
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
    if (_requests.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(child: Text('No leave requests yet', style: TextStyle(color: Colors.grey))),
        ],
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final r = _requests[index];
        final status = (r['status'] as String? ?? 'pending').toLowerCase();
        final color = _statusColor(status);

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
                      '${r['batch_name'] ?? ''} · ${_displayDate(r['session_date'] as String?)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r['description'] as String? ?? '',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                (r['leave_type'] as String? ?? '') == 'advance' ? 'Advance leave' : 'Retroactive leave',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }
}
