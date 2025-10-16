import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

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
  final TextEditingController _locationController = TextEditingController();
  final AppointmentsService _appointmentsService = AppointmentsService();

  // Şirket seçimi ayrı sayfada yapılacak; burada liste tutulmuyor
  CompanyItem? _selectedCompany;
  List<AppointmentStatus> _appointmentStatuses = [];
  AppointmentStatus? _selectedStatus;
  List<AppointmentPriority> _appointmentPriorities = [];
  AppointmentPriority? _selectedPriority;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 30));
  bool _submitting = false;
  bool _loadingStatuses = false;
  bool _loadingPriorities = false;

  @override
  void initState() {
    super.initState();
    _loadAppointmentStatuses();
    _loadAppointmentPriorities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
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

  Future<void> _loadAppointmentPriorities() async {
    setState(() => _loadingPriorities = true);
    try {
      final response = await _appointmentsService.getAppointmentPriorities();
      if (response.success && mounted) {
        setState(() {
          _appointmentPriorities = response.priorities;
          // Default olarak ilk priority'yi seç (genelde "Düşük")
          _selectedPriority = _appointmentPriorities.isNotEmpty ? _appointmentPriorities.first : null;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingPriorities = false);
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

  Future<void> _showPriorityPicker() async {
    if (_appointmentPriorities.isEmpty) return;
    
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
                    Text('Öncelik Seç', style: Theme.of(context).textTheme.titleMedium),
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
                    initialItem: _appointmentPriorities.indexWhere((p) => p.priorityID == (_selectedPriority?.priorityID ?? 1)).clamp(0, _appointmentPriorities.length - 1),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedPriority = _appointmentPriorities[index];
                    });
                  },
                  children: _appointmentPriorities.map((priority) {
                    final Color priorityColor = _parseColor(priority.priorityColor);
                    return Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            priority.priorityName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
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

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.grey;
    } catch (_) {
      return Colors.grey;
    }
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

  Future<void> _showAddToCalendarDialog() async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telefon Takvimine Ekle'),
        content: const Text('Bu randevuyu telefon takviminize eklemek ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    
    if (shouldAdd == true) {
      await _addToCalendar();
    }
  }

  Future<void> _addToCalendar() async {
    try {
      // Randevu başlığını oluştur
      final eventTitle = _titleController.text.trim();
      
      // Notları oluştur
      final notes = StringBuffer();
      notes.writeln('Durum: ${_selectedStatus?.statusName?? ''}');
      if (_descController.text.trim().isNotEmpty) {
        notes.writeln('Açıklama: ${_descController.text.trim()}');
      }
      notes.write('Şirket: ${_selectedCompany?.compName}');
      
      // Takvim etkinliği oluştur
      final event = Event(
        title: eventTitle,
        description: notes.toString(),
        location: _selectedCompany?.compName ?? '',
        startDate: _selectedDateTime,
        endDate: _selectedDateTime.add(const Duration(hours: 1)), // 1 saat varsayılan süre
        allDay: false,
      );
      
      // Takvime ekle
      await Add2Calendar.addEvent2Cal(event);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu takviminize eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Takvime eklenirken hata oluştu: $e')),
        );
      }
    }
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
        appointmentLocation: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        appointmentDate: _formatApiDate(_selectedDateTime),
        appointmentPriority: _selectedPriority?.priorityID ?? 1,
        appointmentStatus: _selectedStatus?.statusID ?? 1,
      );
      if (!mounted) return;
      if (resp.success) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu eklendi')));
        
        // Hemen arkada geri dön - dialog arkaplanda açılacak
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate refresh needed
        }
        
        // Dialog'u arkada göster (non-blocking)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showAddToCalendarDialog();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      // Sadece hata durumunda veya başarısız response'da state'i sıfırla
      if (mounted && _submitting) {
        setState(() => _submitting = false);
      }
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
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Konum (opsiyonel)',
                        prefixIcon: const Icon(Icons.location_on_outlined),
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
                    _buildCupertinoField(
                      placeholder: 'Öncelik',
                      value: _selectedPriority?.priorityName ?? 'Öncelik seçin',
                      onTap: _loadingPriorities ? null : _showPriorityPicker,
                      trailing: _selectedPriority != null ? [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _parseColor(_selectedPriority!.priorityColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ] : null,
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


