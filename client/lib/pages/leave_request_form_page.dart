import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Shared form for both leave flows:
// - "advance": student picks a future date (leaveType == 'advance')
// - "retroactive": date is pre-filled and locked, coming from an Absent row
//   in the attendance list (leaveType == 'retroactive', fixedDate set)
class LeaveRequestFormPage extends StatefulWidget {
  final int batchId;
  final String batchName;
  final String? subjectName;
  final String leaveType;
  final DateTime? fixedDate;

  const LeaveRequestFormPage({
    super.key,
    required this.batchId,
    required this.batchName,
    this.subjectName,
    required this.leaveType,
    this.fixedDate,
  });

  @override
  State<LeaveRequestFormPage> createState() => _LeaveRequestFormPageState();
}

class _LeaveRequestFormPageState extends State<LeaveRequestFormPage> {
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.fixedDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isRetroactive => widget.leaveType == 'retroactive';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService.submitLeaveRequest(
        batchId: widget.batchId,
        sessionDate: _isoDate(_selectedDate!),
        description: _descriptionController.text.trim(),
        leaveType: widget.leaveType,
      );

      if (!mounted) return;

      if ((result['statusCode'] == 200 || result['statusCode'] == 201) && result['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Could not submit leave request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Batch'),
              _readonlyBox('${widget.subjectName ?? ''} · ${widget.batchName}'),
              const SizedBox(height: 20),
              _fieldLabel('Date'),
              if (_isRetroactive)
                _readonlyBox(_selectedDate != null ? _displayDate(_selectedDate!) : '')
              else
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2D1B4E)),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null ? _displayDate(_selectedDate!) : 'Select a date',
                          style: TextStyle(color: _selectedDate != null ? Colors.black : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _fieldLabel('Reason'),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explain why you need leave...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D1B4E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
      );

  Widget _readonlyBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      );
}
