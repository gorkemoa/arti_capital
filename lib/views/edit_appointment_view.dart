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
    this.initialTitleID,
    this.initialPersonIDs,
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
  final int? initialTitleID;
  final List<int>? initialPersonIDs;

  @override
  State<EditAppointmentView> createState() => _EditAppointmentViewState();
}

class _EditAppointmentViewState extends State<EditAppointmentView> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentsService _service = AppointmentsService();

  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _customTitleController;
  late DateTime _selectedDateTime;
  List<AppointmentStatus> _appointmentStatuses = [];
  AppointmentStatus? _selectedStatus;
  List<AppointmentPriority> _appointmentPriorities = [];
  AppointmentPriority? _selectedPriority;
  List<AppointmentRemindType> _appointmentRemindTypes = [];
  AppointmentRemindType? _selectedRemindType;
  List<AppointmentTitle> _appointmentTitles = [];
  AppointmentTitle? _selectedTitle;
  bool _saving = false;
  bool _loadingStatuses = false;
  bool _loadingPriorities = false;
  bool _loadingRemindTypes = false;
  bool _loadingTitles = false;
  
  // Personel seçimi
  List<Map<String, dynamic>> _persons = [];
  List<int> _selectedPersonIDs = [];
  bool _loadingPersons = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.initialDesc);
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
    // Initialize custom title controller - will be populated if "Diğer" is selected
    _customTitleController = TextEditingController();
    _selectedDateTime = _parseTrDateTime(widget.initialDateTimeStr) ?? DateTime.now();
    // Set initial selected person IDs
    _selectedPersonIDs = widget.initialPersonIDs ?? [];
    _loadAppointmentStatuses();
    _loadAppointmentPriorities();
    _loadAppointmentRemindTypes();
    _loadAppointmentTitles();
    _loadPersons();
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

  Future<void> _loadAppointmentTitles() async {
    setState(() => _loadingTitles = true);
    try {
      final response = await _service.getAppointmentTitles();
      if (response.success && mounted) {
        setState(() {
          _appointmentTitles = response.titles;
          // Mevcut titleID'yi seç
          if (widget.initialTitleID != null) {
            _selectedTitle = _appointmentTitles.firstWhere(
              (title) => title.titleID == widget.initialTitleID,
              orElse: () => _appointmentTitles.first,
            );
            // If "Diğer" is selected, populate custom title with initialTitle
            if (_selectedTitle?.isOther == true) {
              _customTitleController.text = widget.initialTitle;
            }
          } else {
            _selectedTitle = null;
          }
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingTitles = false);
    }
  }

  Future<void> _loadPersons() async {
    setState(() => _loadingPersons = true);
    try {
      final persons = await _service.getPersons();
      if (mounted) {
        setState(() {
          _persons = persons;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _loadingPersons = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    _customTitleController.dispose();
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
    
    int initialIndex = _appointmentStatuses.indexWhere((s) => s.statusID == (_selectedStatus?.statusID ?? 1)).clamp(0, _appointmentStatuses.length - 1);
    int tempSelectedIndex = initialIndex;
    
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
                      onPressed: () {
                        setState(() {
                          _selectedStatus = _appointmentStatuses[tempSelectedIndex];
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    tempSelectedIndex = index;
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
    
    int initialIndex = _appointmentPriorities.indexWhere((p) => p.priorityID == (_selectedPriority?.priorityID ?? 1)).clamp(0, _appointmentPriorities.length - 1);
    int tempSelectedIndex = initialIndex;
    
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
                      onPressed: () {
                        setState(() {
                          _selectedPriority = _appointmentPriorities[tempSelectedIndex];
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    tempSelectedIndex = index;
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
    
    int initialIndex = _appointmentRemindTypes.indexWhere((t) => t.typeID == (_selectedRemindType?.typeID ?? 1)).clamp(0, _appointmentRemindTypes.length - 1);
    int tempSelectedIndex = initialIndex;
    
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
                      onPressed: () {
                        setState(() {
                          _selectedRemindType = _appointmentRemindTypes[tempSelectedIndex];
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    tempSelectedIndex = index;
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

  Future<void> _showTitlePicker() async {
    if (_appointmentTitles.isEmpty) return;
    
    int initialIndex = _appointmentTitles.indexWhere((t) => t.titleID == (_selectedTitle?.titleID ?? 1)).clamp(0, _appointmentTitles.length - 1);
    int tempSelectedIndex = initialIndex;
    
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
                    Text('Başlık Seç', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Bitti'),
                      onPressed: () {
                        setState(() {
                          _selectedTitle = _appointmentTitles[tempSelectedIndex];
                          // Clear custom title when switching away from "Diğer"
                          if (_selectedTitle?.isOther == false) {
                            _customTitleController.clear();
                          }
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    tempSelectedIndex = index;
                  },
                  children: _appointmentTitles.map((title) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        title.titleName,
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

  Future<void> _showPersonsPicker() async {
    if (_persons.isEmpty) return;
    
    // Temporary selection list
    List<int> tempSelectedIDs = List.from(_selectedPersonIDs);
    
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Personel Seç'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _persons.length,
                  itemBuilder: (context, index) {
                    final person = _persons[index];
                    final personID = person['id'] as int;
                    final personName = person['name'] as String;
                    final isSelected = tempSelectedIDs.contains(personID);
                    
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isSelected,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            tempSelectedIDs.add(personID);
                          } else {
                            tempSelectedIDs.remove(personID);
                          }
                        });
                      },
                      title: Text(personName),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _selectedPersonIDs = tempSelectedIDs;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Bitti'),
                ),
              ],
            );
          },
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
    if (_selectedTitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen başlık seçin')));
      return;
    }
    
    // Determine the appointment title based on selection
    String appointmentTitle;
    if (_selectedTitle!.isOther) {
      // Use custom title for "Diğer"
      appointmentTitle = _customTitleController.text.trim();
    } else {
      // Use predefined title
      appointmentTitle = _selectedTitle!.titleName;
    }
    
    setState(() => _saving = true);
    try {
      final resp = await _service.updateAppointment(
        compID: widget.compID,
        appointmentID: widget.appointmentID,
        appointmentTitle: appointmentTitle,
        appointmentDesc: _descController.text.trim(),
        appointmentLocation: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        appointmentDate: _formatApiDate(_selectedDateTime),
        appointmentPriority: _selectedPriority?.priorityID ?? 1,
        appointmentStatus: _selectedStatus?.statusID ?? 1,
        remindID: _selectedRemindType?.typeID ?? 1,
        titleID: _selectedTitle!.titleID,
        persons: _selectedPersonIDs.isEmpty ? null : _selectedPersonIDs,
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
                    // Başlık seçimi
                    _buildCupertinoField(
                      placeholder: 'Başlık',
                      value: _selectedTitle?.titleName,
                      onTap: _loadingTitles ? null : _showTitlePicker,
                      prefixIcon: null,
                    ),
                    const SizedBox(height: 12),
                    // Eğer "Diğer" seçiliyse özel başlık girişi göster
                    if (_selectedTitle?.isOther == true) ...[
                      TextFormField(
            textCapitalization: TextCapitalization.sentences,
                        controller: _customTitleController,
                        decoration: InputDecoration(
                          labelText: 'Özel Başlık',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          if (_selectedTitle?.isOther == true && (value == null || value.trim().isEmpty)) {
                            return 'Lütfen başlık giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
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
                      placeholder: 'Personel',
                      value: _selectedPersonIDs.isEmpty 
                          ? null 
                          : '${_selectedPersonIDs.length} personel seçildi',
                      onTap: _loadingPersons ? null : _showPersonsPicker,
                      prefixIcon: const Icon(Icons.people_outline),
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



