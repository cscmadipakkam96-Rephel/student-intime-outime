import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'leave_request_form_page.dart';

class ClassAttendancePage extends StatefulWidget {
  const ClassAttendancePage({super.key});

  @override
  State<ClassAttendancePage> createState() => _ClassAttendancePageState();
}

class _ClassAttendancePageState extends State<ClassAttendancePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

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
      final result = await ApiService.getClassAttendance();
      if (result['statusCode'] == 200 && result['success'] == true) {
        final rows = (result['data'] as List).cast<Map<String, dynamic>>();
        // Newest first.
        rows.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
        setState(() => _rows = rows);
      } else {
        setState(() => _error = result['error']?.toString() ?? 'Failed to load attendance');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitLeaveFor(Map<String, dynamic> row) async {
    final batchId = row['batch_id'] as int?;
    if (batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not identify this batch — please contact your teacher')),
      );
      return;
    }

    final date = DateTime.tryParse(row['date'] as String);
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LeaveRequestFormPage(
          batchId: batchId,
          batchName: row['batch_name'] as String? ?? '',
          subjectName: row['subject_name'] as String?,
          leaveType: 'retroactive',
          fixedDate: date,
        ),
      ),
    );

    if (submitted == true) _load();
  }

  String _displayDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
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
                  'My Attendance',
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
    if (_rows.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(child: Text('No attendance records yet', style: TextStyle(color: Colors.grey))),
        ],
      );
    }

    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        final isPresent = row['status'] == 'Present';
        final hasLeaveRequest = row['hasLeaveRequest'] == true;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayDate(row['date'] as String),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${row['subject_name'] ?? ''} · ${row['batch_name'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if ((row['topic_covered'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Topic: ${row['topic_covered']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPresent ? const Color(0xFFE3F5EA) : const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      row['status'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPresent ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isPresent && !hasLeaveRequest) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D1B4E),
                      side: const BorderSide(color: Color(0xFF2D1B4E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _submitLeaveFor(row),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Submit Leave Letter'),
                  ),
                ),
              ],
              if (!isPresent && hasLeaveRequest) ...[
                const SizedBox(height: 10),
                Text(
                  'Leave letter already submitted',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
