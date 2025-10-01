import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/company_models.dart';
import '../models/appointment_models.dart';
import '../services/appointments_service.dart';
import '../theme/app_colors.dart';
import 'company_detail_view.dart';

class NewAppointmentView extends StatefulWidget {
  const NewAppointmentView({super.key});

  @override
  State<NewAppointmentView> createState() => _NewAppointmentViewState();
}

class _NewAppointmentViewState extends State<NewAppointmentView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final AppointmentsService _appointmentsService = AppointmentsService();

  // Şirket seçimi ayrı sayfada yapılacak; burada liste tutulmuyor
  CompanyItem? _selectedCompany;
  List<AppointmentStatus> _appointmentStatuses = [];
  AppointmentStatus? _selectedStatus;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 30));
  bool _submitting = false;
  bool _loadingStatuses = false;

  @override
  void initState() {
    super.initState();
    _loadAppointmentStatuses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointmentStatuses() async {
    setState(() => _loadingStatuses = true);
    try {
      final response = await _appointmentsService.getAppointmentStatuses();
      if (response.success && mounted) {
        setState(() {
          _appointmentStatuses = response.statuses;
          // Default olarak "Yeni Randevu" (statusID: 1) seç
          _selectedStatus = _appointmentStatuses.firstWhere(
            (status) => status.statusID == 1,
            orElse: () => _appointmentStatuses.isNotEmpty ? _appointmentStatuses.first : _appointmentStatuses.first,
          );
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  // init state gerekmiyor; şirket seçimi ayrı sayfada yapılacak

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
                  minimumDate: DateTime.now().subtract(const Duration(days: 0)),
                  maximumDate: DateTime.now().add(const Duration(days: 365 * 2)),
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

  Future<void> _showStatusPicker() async {
    if (_appointmentStatuses.isEmpty) return;
    
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
                    Text('Durum Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Bitti'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: _appointmentStatuses.indexWhere((s) => s.statusID == (_selectedStatus?.statusID ?? 1)).clamp(0, _appointmentStatuses.length - 1),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedStatus = _appointmentStatuses[index];
                    });
                  },
                  children: _appointmentStatuses.map((status) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        status.statusName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Cupertino selector bu sayfada kullanılmıyor

  Widget _buildCupertinoField({
    required String placeholder,
    required String? value,
    required VoidCallback? onTap,
    List<Widget>? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (value == null || value.isEmpty)
                      ? AppColors.onSurface.withOpacity(0.6)
                      : AppColors.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...trailing,
            Icon(CupertinoIcons.chevron_down, size: 18, color: AppColors.onSurface.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen şirket seçin')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final resp = await _appointmentsService.addAppointment(
        compID: _selectedCompany!.compID,
        appointmentTitle: _titleController.text.trim(),
        appointmentDesc: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        appointmentDate: _formatApiDate(_selectedDateTime),
        appointmentStatus: _selectedStatus?.statusID ?? 1,
      );
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu eklendi')));
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Randevu'), backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
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
                    Text('Randevu Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    // Şirket seçimi - Cupertino alanı ve detay butonu
                    _buildCupertinoField(
                      placeholder: 'Şirket',
                      value: _selectedCompany?.compName,
                      onTap: () async {
                        final result = await Navigator.of(context).pushNamed('/select-company');
                        if (result is CompanyItem) {
                          setState(() => _selectedCompany = result);
                        }
                      },
                      trailing: _selectedCompany != null
                          ? [
                              IconButton(
                                tooltip: 'Şirketi Görüntüle',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CompanyDetailView(compId: _selectedCompany!.compID),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.open_in_new),
                              )
                            ]
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildCupertinoField(
                      placeholder: 'Durum',
                      value: _selectedStatus?.statusName,
                      onTap: _loadingStatuses ? null : _showStatusPicker,
                    ),
                    const SizedBox(height: 12),
                    _buildCupertinoField(
                      placeholder: 'Tarih / Saat',
                      value: _formatApiDate(_selectedDateTime),
                      onTap: _pickDateTime,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Alt buton çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
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


