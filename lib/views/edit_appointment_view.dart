import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../models/appointment_models.dart';
import '../services/appointments_service.dart';

class EditAppointmentView extends StatefulWidget {
  const EditAppointmentView({
    super.key,
    required this.appointmentID,
    required this.compID,
    required this.initialTitle,
    required this.initialDesc,
    required this.initialDateTimeStr, // dd.MM.yyyy HH:mm
    this.initialStatusID,
    this.initialLocation,
    this.initialPriority,
    this.initialRemindID,
  });

  final int appointmentID;
  final int compID;
  final String initialTitle;
  final String initialDesc;
  final String initialDateTimeStr;
  final int? initialStatusID;
  final String? initialLocation;
  final int? initialPriority;
  final int? initialRemindID;

  @override
  State<EditAppointmentView> createState() => _EditAppointmentViewState();
}

class _EditAppointmentViewState extends State<EditAppointmentView> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentsService _service = AppointmentsService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late DateTime _selectedDateTime;
  List<AppointmentStatus> _appointmentStatuses = [];
  AppointmentStatus? _selectedStatus;
  List<AppointmentPriority> _appointmentPriorities = [];
  AppointmentPriority? _selectedPriority;
  List<AppointmentRemindType> _appointmentRemindTypes = [];
  AppointmentRemindType? _selectedRemindType;
  bool _saving = false;
  bool _loadingStatuses = false;
  bool _loadingPriorities = false;
  bool _loadingRemindTypes = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDesc);
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
    _selectedDateTime = _parseTrDateTime(widget.initialDateTimeStr) ?? DateTime.now();
    _loadAppointmentStatuses();
    _loadAppointmentPriorities();
    _loadAppointmentRemindTypes();
  }

  Future<void> _loadAppointmentStatuses() async {
    setState(() => _loadingStatuses = true);
    try {
      final response = await _service.getAppointmentStatuses();
      if (response.success && mounted) {
        setState(() {
          _appointmentStatuses = response.statuses;
          // Mevcut status'u seç
          if (widget.initialStatusID != null) {
            _selectedStatus = _appointmentStatuses.firstWhere(
              (status) => status.statusID == widget.initialStatusID,
              orElse: () => _appointmentStatuses.first,
            );
          } else {
            _selectedStatus = null;
          }
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
      final response = await _service.getAppointmentPriorities();
      if (response.success && mounted) {
        setState(() {
          _appointmentPriorities = response.priorities;
          // Mevcut priority'yi seç
          if (widget.initialPriority != null) {
            _selectedPriority = _appointmentPriorities.firstWhere(
              (priority) => priority.priorityID == widget.initialPriority,
              orElse: () => _appointmentPriorities.first,
            );
          } else {
            _selectedPriority = null;
          }
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingPriorities = false);
    }
  }

  Future<void> _loadAppointmentRemindTypes() async {
    setState(() => _loadingRemindTypes = true);
    try {
      final response = await _service.getAppointmentRemindTypes();
      if (response.success && mounted) {
        setState(() {
          _appointmentRemindTypes = response.types;
          // Mevcut remindID'yi seç
          if (widget.initialRemindID != null) {
            _selectedRemindType = _appointmentRemindTypes.firstWhere(
              (type) => type.typeID == widget.initialRemindID,
              orElse: () => _appointmentRemindTypes.first,
            );
          } else {
            _selectedRemindType = null;
          }
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingRemindTypes = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
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

  Future<void> _showRemindTypePicker() async {
    if (_appointmentRemindTypes.isEmpty) return;
    
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
                    Text('Hatırlatma Seç', style: Theme.of(context).textTheme.titleMedium),
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
                    initialItem: _appointmentRemindTypes.indexWhere((t) => t.typeID == (_selectedRemindType?.typeID ?? 1)).clamp(0, _appointmentRemindTypes.length - 1),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedRemindType = _appointmentRemindTypes[index];
                    });
                  },
                  children: _appointmentRemindTypes.map((remindType) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        remindType.typeName,
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

  Widget _buildCupertinoField({
    required String placeholder,
    required String? value,
    required VoidCallback? onTap,
    List<Widget>? trailing,
    Widget? prefixIcon,
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
            if (prefixIcon != null) ...[
              prefixIcon,
              const SizedBox(width: 8),
            ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final resp = await _service.updateAppointment(
        compID: widget.compID,
        appointmentID: widget.appointmentID,
        appointmentTitle: _titleController.text.trim(),
        appointmentDesc: _descController.text.trim(),
        appointmentLocation: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        appointmentDate: _formatApiDate(_selectedDateTime),
        appointmentPriority: _selectedPriority?.priorityID ?? 1,
        appointmentStatus: _selectedStatus?.statusID ?? 1,
        remindID: _selectedRemindType?.typeID ?? 1,
      );
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu güncellendi')),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
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
                    Text('Randevu Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
            textCapitalization: TextCapitalization.sentences,
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
            textCapitalization: TextCapitalization.sentences,
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
                    TextFormField(
            textCapitalization: TextCapitalization.sentences,
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Konum (opsiyonel)',
                        prefixIcon: const Icon(Icons.location_on_outlined),
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
                    _buildCupertinoField(
                      placeholder: 'Öncelik',
                      value: _selectedPriority?.priorityName,
                      onTap: _loadingPriorities ? null : _showPriorityPicker,
                      prefixIcon: const Icon(Icons.flag_outlined),
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
                      prefixIcon: const Icon(Icons.task_alt),
                    ),
                    const SizedBox(height: 12),
                    _buildCupertinoField(
                      placeholder: 'Hatırlatma',
                      value: _selectedRemindType?.typeName,
                      onTap: _loadingRemindTypes ? null : _showRemindTypePicker,
                      prefixIcon: const Icon(Icons.notifications_outlined),
                    ),
                    const SizedBox(height: 12),
                    _buildCupertinoField(
                      placeholder: 'Tarih / Saat',
                      value: _formatApiDate(_selectedDateTime),
                      onTap: _pickDateTime,
                      prefixIcon: const Icon(Icons.event),
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



