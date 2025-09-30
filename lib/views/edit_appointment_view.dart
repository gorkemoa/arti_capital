import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../services/appointments_service.dart';

class EditAppointmentView extends StatefulWidget {
  const EditAppointmentView({
    super.key,
    required this.appointmentID,
    required this.compID,
    required this.initialTitle,
    required this.initialDesc,
    required this.initialDateTimeStr, // dd.MM.yyyy HH:mm
  });

  final int appointmentID;
  final int compID;
  final String initialTitle;
  final String initialDesc;
  final String initialDateTimeStr;

  @override
  State<EditAppointmentView> createState() => _EditAppointmentViewState();
}

class _EditAppointmentViewState extends State<EditAppointmentView> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentsService _service = AppointmentsService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDateTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDesc);
    _selectedDateTime = _parseTrDateTime(widget.initialDateTimeStr) ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  static DateTime? _parseTrDateTime(String raw) {
    try {
      final parts = raw.split(' ');
      if (parts.length < 2) return null;
      final datePart = parts[0];
      final timePart = parts[1];
      final d = datePart.split('.');
      final t = timePart.split(':');
      if (d.length != 3 || t.length < 2) return null;
      return DateTime(int.parse(d[2]), int.parse(d[1]), int.parse(d[0]), int.parse(t[0]), int.parse(t[1]));
    } catch (_) {
      return null;
    }
  }

  static String _formatApiDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _pickDateTime() async {
    // First pick date
    DateTime tempDate = _selectedDateTime;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    Text('Tarih Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Devam'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _pickTime(tempDate);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDateTime,
                  minimumDate: DateTime.now().subtract(const Duration(days: 365)),
                  maximumDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  onDateTimeChanged: (d) { tempDate = d; },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(DateTime selectedDate) async {
    // Then pick time
    DateTime tempDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );
    
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Geri'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _pickDateTime(); // Go back to date picker
                      },
                    ),
                    Text('Saat Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Bitti'),
                      onPressed: () {
                        setState(() {
                          _selectedDateTime = tempDateTime;
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempDateTime,
                  onDateTimeChanged: (d) {
                    tempDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      d.hour,
                      d.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final resp = await _service.updateAppointment(
        compID: widget.compID,
        appointmentID: widget.appointmentID,
        appointmentTitle: _titleController.text.trim(),
        appointmentDesc: _descController.text.trim(),
        appointmentDate: _formatApiDate(_selectedDateTime),
        appointmentStatus: 1,
      );
      if (!mounted) return;
      if (resp.success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Düzenle'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama (opsiyonel)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.event),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatApiDate(_selectedDateTime),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))]),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



