import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  final String studentName;

  const DashboardPage({super.key, required this.studentName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  late final Timer _timer;
  DateTime _now = DateTime.now();

  bool _loadingHistory = true;
  bool _actionLoading = false;
  String? _loadError;

  // All attendance records for this student, newest first (from backend).
  List<Map<String, dynamic>> _records = [];

  DateTime? _todayInTime;
  DateTime? _todayOutTime;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _loadError = null;
    });

    try {
      final result = await ApiService.getHistory();

      if (result['statusCode'] == 200 && result['success'] == true) {
        final records = (result['records'] as List).cast<Map<String, dynamic>>();

        Map<String, dynamic>? todayRecord;
        for (final record in records) {
          final date = DateTime.parse(record['date'] as String);
          if (_isSameDay(date, DateTime.now())) {
            todayRecord = record;
            break;
          }
        }

        setState(() {
          _records = records;
          // Backend sends UTC timestamps (Postgres); convert to the
          // device's local time before displaying, or times will be off
          // by the local UTC offset (e.g. shown ~5:30 behind in IST).
          _todayInTime = todayRecord != null && todayRecord['inTime'] != null
              ? DateTime.parse(todayRecord['inTime'] as String).toLocal()
              : null;
          _todayOutTime = todayRecord != null && todayRecord['outTime'] != null
              ? DateTime.parse(todayRecord['outTime'] as String).toLocal()
              : null;
        });
      } else {
        setState(() => _loadError = result['error']?.toString() ?? 'Failed to load history');
      }
    } catch (e) {
      setState(() => _loadError = 'Could not reach server: $e');
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _markInTime() async {
    setState(() => _actionLoading = true);
    try {
      final result = await ApiService.markInTime();
      if (result['statusCode'] == 200 && result['success'] == true) {
        await _loadHistory();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Could not mark in-time')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _markOutTime() async {
    setState(() => _actionLoading = true);
    try {
      final result = await ApiService.markOutTime();
      if (result['statusCode'] == 200 && result['success'] == true) {
        await _loadHistory();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Could not mark out-time')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  String _formatDate(DateTime dt) {
    return '${_weekdays[dt.weekday - 1]}, ${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.studentName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready for today at CSC?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Live date + time card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D1B4E), Color(0xFF1A1025)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today, color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(_now),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _formatTime(_now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Single toggle button: In Time -> Out Time -> done for today
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D1B4E),
                      disabledBackgroundColor: const Color(0xFF8C7AA6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _actionLoading
                        ? null
                        : _todayInTime == null
                            ? _markInTime
                            : _todayOutTime == null
                                ? _markOutTime
                                : null,
                    icon: Icon(
                      _todayInTime == null
                          ? Icons.login
                          : _todayOutTime == null
                              ? Icons.logout
                              : Icons.check_circle,
                      color: Colors.white,
                    ),
                    label: Text(
                      _todayInTime == null
                          ? 'In Time'
                          : _todayOutTime == null
                              ? 'Out Time'
                              : 'Done for today (In: ${_formatTime(_todayInTime!)} · Out: ${_formatTime(_todayOutTime!)})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                if (_todayInTime != null) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Check-in recorded successfully',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (_loadingHistory)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ))
                else if (_loadError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                else if (_records.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No attendance records yet', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._records.map((record) {
                    final date = DateTime.parse(record['date'] as String).toLocal();
                    final inTime = record['inTime'] != null
                        ? DateTime.parse(record['inTime'] as String).toLocal()
                        : null;
                    final outTime = record['outTime'] != null
                        ? DateTime.parse(record['outTime'] as String).toLocal()
                        : null;
                    return _historyCard(date: date, inTime: inTime, outTime: outTime);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyCard({required DateTime date, DateTime? inTime, DateTime? outTime}) {
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
              color: const Color(0xFFE3F5EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'In: ${inTime != null ? _formatTime(inTime) : '--'}   Out: ${outTime != null ? _formatTime(outTime) : '--'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
