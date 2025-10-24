import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../services/logger.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class EditTrackingView extends StatefulWidget {
  final ProjectTracking tracking;
  final int projectID;
  final int compID;
  final String projectTitle;

  const EditTrackingView({
    super.key,
    required this.tracking,
    required this.projectID,
    required this.compID,
    required this.projectTitle,
  });

  @override
  State<EditTrackingView> createState() => _EditTrackingViewState();
}

class _EditTrackingViewState extends State<EditTrackingView> {
  final ProjectsService _service = ProjectsService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _dueDateController;
  late TextEditingController _remindDateController;
  
  late int _selectedTypeID;
  late int _selectedStatusID;
  late int _selectedUserID;
  String? _selectedNotificationType;
  bool _isLoading = false;

  final List<String> _notificationTypes = ['push', 'email', 'sms', 'all'];

  List<FollowupType> trackingTypes = [];
  List<FollowupStatus> statuses = [];
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tracking.trackTitle);
    _descController = TextEditingController(text: widget.tracking.trackDesc);
    _dueDateController = TextEditingController(text: widget.tracking.trackDueDate);
    _remindDateController = TextEditingController(text: widget.tracking.trackRemindDate);
    
    // Mevcut değerleri başlat
    _selectedTypeID = widget.tracking.trackTypeID;
    _selectedStatusID = widget.tracking.trackStatusID;
    _selectedUserID = widget.tracking.assignedUserID;
    _selectedNotificationType = widget.tracking.notificationType;
    
    // Debug: Gelen değerleri logla
    print('🔍 EDIT_TRACKING - TypeID: $_selectedTypeID, TypeName: ${widget.tracking.trackTypeName}');
    print('🔍 EDIT_TRACKING - StatusID: $_selectedStatusID, StatusName: ${widget.tracking.statusName}');
    print('🔍 EDIT_TRACKING - UserID: $_selectedUserID, UserName: ${widget.tracking.assignedUser}');
    
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final fetchedTypes = await _service.getFollowupTypes();
      final fetchedStatuses = await _service.getFollowupStatuses();
      final fetchedPersons = await _service.getPersons();
      
      print('✅ Dropdown Data Loaded:');
      print('   Types: ${fetchedTypes.length} items');
      print('   Statuses: ${fetchedStatuses.length} items');
      print('   Users: ${fetchedPersons.length} items');
      
      // Statü ID'sini ad ile eşleştir (API'den gelen ad ile)
      int matchedStatusID = _selectedStatusID;
      if (matchedStatusID == 0 || matchedStatusID < 0) {
        // trackStatusID yanlışsa, statü adına göre ara
        try {
          final matchedStatus = fetchedStatuses.firstWhere(
            (s) => s.statusName.toLowerCase() == widget.tracking.statusName.toLowerCase(),
            orElse: () => fetchedStatuses.isNotEmpty ? fetchedStatuses[0] : FollowupStatus(statusID: 0, statusName: '', statusColor: ''),
          );
          matchedStatusID = matchedStatus.statusID;
          print('🔍 Statü eşleştirildi: "${widget.tracking.statusName}" -> ID: $matchedStatusID');
        } catch (e) {
          print('⚠️ Statü eşleştirilemedi: $e');
        }
      }

      // Tür ID'sini ad ile eşleştir (API'den gelen ad ile)
      int matchedTypeID = _selectedTypeID;
      if (matchedTypeID == 0 || matchedTypeID < 0) {
        // trackTypeID yanlışsa, tür adına göre ara
        try {
          final matchedType = fetchedTypes.firstWhere(
            (t) => t.typeName.toLowerCase() == widget.tracking.trackTypeName.toLowerCase(),
            orElse: () => fetchedTypes.isNotEmpty ? fetchedTypes[0] : FollowupType(typeID: 0, typeName: ''),
          );
          matchedTypeID = matchedType.typeID;
          print('🔍 Tür eşleştirildi: "${widget.tracking.trackTypeName}" -> ID: $matchedTypeID');
        } catch (e) {
          print('⚠️ Tür eşleştirilemedi: $e');
        }
      }

      // Kullanıcı ID'sini ad ile eşleştir (API'den gelen ad ile)
      int matchedUserID = _selectedUserID;
      if (matchedUserID == 0 || matchedUserID < 0) {
        // assignedUserID yanlışsa, kullanıcı adına göre ara
        try {
          final matchedUser = fetchedPersons.firstWhere(
            (u) => (u['name'] as String).toLowerCase().trim() == widget.tracking.assignedUser.toLowerCase().trim(),
            orElse: () => fetchedPersons.isNotEmpty ? fetchedPersons[0] : {'id': 0, 'name': ''},
          );
          matchedUserID = matchedUser['id'] as int;
          print('🔍 Kullanıcı eşleştirildi: "${widget.tracking.assignedUser}" -> ID: $matchedUserID');
        } catch (e) {
          print('⚠️ Kullanıcı eşleştirilemedi: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          trackingTypes = fetchedTypes;
          statuses = fetchedStatuses;
          users = fetchedPersons;
          _selectedStatusID = matchedStatusID;
          _selectedTypeID = matchedTypeID;
          _selectedUserID = matchedUserID;
        });
        
        print('🔄 After setState:');
        print('   Selected Type: ${_getSelectedTypeName()}');
        print('   Selected Status: ${_getSelectedStatusName()}');
        print('   Selected User: ${_getSelectedUserName()}');
      }
    } catch (e) {
      print('❌ Error loading dropdown data: $e');
      AppLogger.e('Error loading dropdown data: $e', tag: 'EDIT_TRACKING_DROPDOWN');
    }
  }
  
  String _getSelectedTypeName() {
    if (trackingTypes.isEmpty) {
      // Dropdown henüz yüklenmediyse tracking'ten gelen ismi göster
      return widget.tracking.trackTypeName;
    }
    try {
      final type = trackingTypes.firstWhere((t) => t.typeID == _selectedTypeID);
      return type.typeName;
    } catch (e) {
      // ID bulunamazsa tracking'ten gelen ismi göster
      return widget.tracking.trackTypeName;
    }
  }

  String _getSelectedStatusName() {
    if (statuses.isEmpty) {
      // Dropdown henüz yüklenmediyse tracking'ten gelen ismi göster
      return widget.tracking.statusName;
    }
    try {
      final status = statuses.firstWhere((s) => s.statusID == _selectedStatusID);
      return status.statusName;
    } catch (e) {
      // ID bulunamazsa tracking'ten gelen ismi göster
      return widget.tracking.statusName;
    }
  }

  String _getSelectedUserName() {
    if (users.isEmpty) {
      // Dropdown henüz yüklenmediyse tracking'ten gelen ismi göster
      return widget.tracking.assignedUser;
    }
    try {
      final user = users.firstWhere((u) => u['id'] == _selectedUserID);
      return user['name'] as String;
    } catch (e) {
      // ID bulunamazsa tracking'ten gelen ismi göster
      return widget.tracking.assignedUser;
    }
  }

  String _formatNotificationType(String? type) {
    if (type == null) return 'Bildirim türü seçiniz';
    switch (type.toLowerCase()) {
      case 'push':
        return 'Push Bildirim';
      case 'email':
        return 'E-posta';
      case 'sms':
        return 'SMS';
      case 'all':
        return 'Tümü';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    _remindDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    await _showCupertinoDatePicker(controller);
  }

  Future<void> _showCupertinoDatePicker(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime selectedDate = now;

    // Parse existing date if available
    if (controller.text.isNotEmpty) {
      try {
        selectedDate = DateFormat('dd.MM.yyyy').parse(controller.text);
      } catch (_) {
        selectedDate = now;
      }
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          controller.text = DateFormat('dd.MM.yyyy').format(selectedDate);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date fields
    if (_dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitiş tarihi gereklidir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_remindDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatırlatma tarihi gereklidir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.updateTracking(
        trackID: widget.tracking.trackID,
        appID: widget.projectID,
        compID: widget.compID,
        typeID: _selectedTypeID,
        statusID: _selectedStatusID,
        trackTitle: _titleController.text,
        trackDesc: _descController.text,
        trackDueDate: _dueDateController.text,
        trackRemindDate: _remindDateController.text,
        assignedUserID: _selectedUserID,
        notificationType: _selectedNotificationType,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip güncellenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCupertinoField({
    required String placeholder,
    required String value,
    VoidCallback? onTap,
    bool isDisabled = false,
    Widget? prefix,
  }) {
    final isEmpty = value.isEmpty || 
                    value == placeholder ||
                    value == 'Bildirim türü seçiniz' ||
                    value.contains('seçiniz') ||
                    value.contains('Yükleniyor');
    
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled 
              ? AppColors.onSurface.withOpacity(0.03)
              : AppColors.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prefix != null) ...[
              prefix,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEmpty
                      ? AppColors.onSurface.withOpacity(isDisabled ? 0.4 : 0.4)
                      : AppColors.onSurface.withOpacity(isDisabled ? 0.5 : 1),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: AppColors.onSurface.withOpacity(isDisabled ? 0.3 : 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypePicker() async {
    if (trackingTypes.isEmpty) return;

    int selectedIndex = trackingTypes.indexWhere((t) => t.typeID == _selectedTypeID);
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedTypeID = trackingTypes[selectedIndex].typeID;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: trackingTypes.map((type) => Center(child: Text(type.typeName))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusPicker() async {
    if (statuses.isEmpty) return;

    int selectedIndex = statuses.indexWhere((s) => s.statusID == _selectedStatusID);
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedStatusID = statuses[selectedIndex].statusID;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: statuses.map((status) {
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseHexColor(status.statusColor),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.statusName),
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

  Future<void> _showUserPicker() async {
    if (users.isEmpty) return;

    int selectedIndex = users.indexWhere((u) => u['id'] == _selectedUserID);
    if (selectedIndex < 0) selectedIndex = 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedUserID = users[selectedIndex]['id'] as int;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: users.map((user) => Center(child: Text(user['name'] as String))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotificationTypePicker() async {
    int selectedIndex = 0;
    if (_selectedNotificationType != null) {
      selectedIndex = _notificationTypes.indexOf(_selectedNotificationType!);
      if (selectedIndex < 0) selectedIndex = 0;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedNotificationType = _notificationTypes[selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 32,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: _notificationTypes
                      .map((type) => Center(
                            child: Text(
                              type == 'push'
                                  ? 'Push Bildirim'
                                  : type == 'email'
                                      ? 'E-posta'
                                      : type == 'sms'
                                          ? 'SMS'
                                          : 'Tümü',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Durumu Güncelle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        _buildFormSection(
                          title: 'Başlık *',
                          child: TextFormField(
                            controller: _titleController,
                            decoration: _buildInputDecoration(
                              hintText: 'Örn: Müşteri görüşmesi',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Başlık gereklidir';
                              }
                              return null;
                            },
                          ),
                          theme: theme,
                        ),

                        // Açıklama
                        _buildFormSection(
                          title: 'Açıklama *',
                          child: TextFormField(
                            controller: _descController,
                            decoration: _buildInputDecoration(
                              hintText: 'Detayları yazınız...',
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Açıklama gereklidir';
                              }
                              return null;
                            },
                          ),
                          theme: theme,
                        ),

                        // Tip ve Durum
                        _buildFormSection(
                          title: 'Kategoriler',
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Durum *',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCupertinoField(
                                      placeholder: 'Statü *',
                                      value: _getSelectedStatusName(),
                                      onTap: _showStatusPicker,
                                      isDisabled: statuses.isEmpty,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tip *',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCupertinoField(
                                      placeholder: 'Tip *',
                                      value: _getSelectedTypeName(),
                                      onTap: _showTypePicker,
                                      isDisabled: trackingTypes.isEmpty,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          theme: theme,
                        ),

                        // Tarihler
                        _buildFormSection(
                          title: 'Tarihler',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bitiş Tarihi *',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCupertinoField(
                                          placeholder: 'DD.MM.YYYY',
                                          value: _dueDateController.text.isEmpty ? 'DD.MM.YYYY' : _dueDateController.text,
                                          onTap: () => _selectDate(_dueDateController),
                                          prefix: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              CupertinoIcons.calendar,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hatırlatma Tarihi *',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCupertinoField(
                                          placeholder: 'DD.MM.YYYY',
                                          value: _remindDateController.text.isEmpty ? 'DD.MM.YYYY' : _remindDateController.text,
                                          onTap: () => _selectDate(_remindDateController),
                                          prefix: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              CupertinoIcons.calendar,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          theme: theme,
                        ),

                        // Atanan Kişi
                        _buildFormSection(
                          title: 'Atanan Kişi *',
                          child: _buildCupertinoField(
                            placeholder: 'Atanan Kişi *',
                            value: _getSelectedUserName(),
                            onTap: _showUserPicker,
                            isDisabled: users.isEmpty,
                          ),
                          theme: theme,
                        ),

                        // Bildirim Türü (Opsiyonel)
                        _buildFormSection(
                          title: 'Bildirim Türü (Opsiyonel)',
                          child: _buildCupertinoField(
                            placeholder: 'Bildirim türü seçiniz',
                            value: _formatNotificationType(_selectedNotificationType),
                            onTap: _showNotificationTypePicker,
                          ),
                          theme: theme,
                        ),

                        const SizedBox(height: 32),

                        // Butonlar
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(false),
                                icon: const Icon(Icons.close),
                                label: const Text('İptal'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _submitForm,
                                icon: const Icon(Icons.check),
                                label: const Text('Güncelle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required Widget child,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.onSurface.withOpacity(0.4),
      ),
      suffixIcon: suffixIcon != null
          ? Icon(
              suffixIcon,
              color: AppColors.primary.withOpacity(0.5),
              size: 20,
            )
          : null,
      filled: true,
      fillColor: AppColors.onSurface.withOpacity(0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
    );
  }

  Color _parseHexColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (_) {
      return AppColors.primary;
    }
  }
}
