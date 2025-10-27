import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/projects_service.dart';
import '../services/logger.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AddTrackingView extends StatefulWidget {
  final int projectID;
  final int compID;
  final String projectTitle;

  const AddTrackingView({
    super.key,
    required this.projectID,
    required this.compID,
    required this.projectTitle,
  });

  @override
  State<AddTrackingView> createState() => _AddTrackingViewState();
}

class _AddTrackingViewState extends State<AddTrackingView> {
  final ProjectsService _service = ProjectsService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _dueDateController;
  late TextEditingController _remindDateController;
  late TextEditingController _customTitleController;
  
  int _selectedTypeID = -1;
  int _selectedTitleID = -1;
  int _selectedStatusID = -1;
  List<int> _selectedUserIDs = [];
  List<String> _selectedNotificationTypes = [];
  bool _isLoading = false;
  bool _isOtherTitleSelected = false;

  // Notification type options
  final List<String> _notificationTypes = ['push', 'email', 'sms'];

  // Mock data for dropdowns
  List<Map<String, dynamic>> trackingTypes = [];

  List<Map<String, dynamic>> trackingTitles = [];

  List<Map<String, dynamic>> statuses = [];

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _dueDateController = TextEditingController();
    _remindDateController = TextEditingController();
    _customTitleController = TextEditingController();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final fetchedTypes = await _service.getFollowupTypes();
      final fetchedTitles = await _service.getFollowupTitles();
      final fetchedStatuses = await _service.getFollowupStatuses();
      final fetchedPersons = await _service.getPersons();
      
      if (mounted) {
        setState(() {
          trackingTypes = fetchedTypes
              .map((type) => {
                    'id': type.typeID,
                    'name': type.typeName,
                  })
              .toList();
          
          trackingTitles = fetchedTitles
              .map((title) => {
                    'id': title.titleID,
                    'name': title.titleName,
                    'isOther': title.isOther,
                  })
              .toList();
          
          statuses = fetchedStatuses
              .map((status) => {
                    'id': status.statusID,
                    'name': status.statusName,
                    'color': status.statusColor,
                  })
              .toList();
          
          users = fetchedPersons;
          
          // Set default values if data loaded (don't auto-select first item)
          // User must explicitly select
        });
      }
    } catch (e) {
      AppLogger.e('Error loading dropdown data: $e', tag: 'ADD_TRACKING_DROPDOWN');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    _remindDateController.dispose();
    _customTitleController.dispose();
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
    // Validate type selection
    if (_selectedTypeID == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir tip seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate title selection
    if (_selectedTitleID == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir başlık türü seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate status selection
    if (_selectedStatusID == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir durum seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that at least one user is selected
    if (_selectedUserIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir kişi seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate custom title if "Other" is selected
    if (_isOtherTitleSelected && _customTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen özel başlık giriniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If "Other" is selected, use custom title, otherwise use empty or selected title name
      final trackTitle = _isOtherTitleSelected 
          ? _customTitleController.text.trim()
          : ''; // Başlık türü seçiliyse boş gönder, API'de başlık türü kullanılacak

      final response = await _service.addTracking(
        appID: widget.projectID,
        compID: widget.compID,
        typeID: _selectedTypeID,
        titleID: _selectedTitleID,
        statusID: _selectedStatusID,
        trackTitle: trackTitle,
        trackDesc: _descController.text,
        trackDueDate: _dueDateController.text,
        trackRemindDate: _remindDateController.text,
        assignedUserIDs: _selectedUserIDs,
        notificationTypes: _selectedNotificationTypes.isNotEmpty ? _selectedNotificationTypes : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Takip oluşturulamadı'),
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
    String? value,
    VoidCallback? onTap,
    bool isDisabled = false,
    Widget? prefix,
  }) {
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
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: (value == null || value.isEmpty)
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

    int selectedIndex = trackingTypes.indexWhere((t) => t['id'] == _selectedTypeID);
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
                          _selectedTypeID = trackingTypes[selectedIndex]['id'] as int;
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
                  children: trackingTypes.map((type) => Center(child: Text(type['name'] as String))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTitlePicker() async {
    if (trackingTitles.isEmpty) return;

    int selectedIndex = trackingTitles.indexWhere((t) => t['id'] == _selectedTitleID);
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
                          _selectedTitleID = trackingTitles[selectedIndex]['id'] as int;
                          _isOtherTitleSelected = trackingTitles[selectedIndex]['isOther'] as bool? ?? false;
                          // Clear custom title if not "Other"
                          if (!_isOtherTitleSelected) {
                            _customTitleController.clear();
                          }
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
                  children: trackingTitles.map((title) => Center(child: Text(title['name'] as String))).toList(),
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

    int selectedIndex = statuses.indexWhere((s) => s['id'] == _selectedStatusID);
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
                          _selectedStatusID = statuses[selectedIndex]['id'] as int;
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
                              color: _parseHexColor(status['color'] as String),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status['name'] as String),
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

    // Show a multi-select dialog
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // Create a local copy for the dialog state
        List<int> tempSelectedUserIDs = List.from(_selectedUserIDs);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Atanan Kişiler Seçiniz'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['id'] as int;
                    final userName = user['name'] as String;
                    final isSelected = tempSelectedUserIDs.contains(userId);

                    return CheckboxListTile(
                      title: Text(userName),
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedUserIDs.add(userId);
                          } else {
                            tempSelectedUserIDs.remove(userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedUserIDs = tempSelectedUserIDs;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationTypePicker() async {
    // Show a multi-select dialog
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // Create a local copy for the dialog state
        List<String> tempSelectedNotificationTypes = List.from(_selectedNotificationTypes);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Bildirim Türleri Seçiniz'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notificationTypes.length,
                  itemBuilder: (context, index) {
                    final notifType = _notificationTypes[index];
                    final isSelected = tempSelectedNotificationTypes.contains(notifType);
                    
                    String displayName;
                    switch (notifType) {
                      case 'push':
                        displayName = 'Bildirim';
                        break;
                      case 'email':
                        displayName = 'E-posta';
                        break;
                      case 'sms':
                        displayName = 'SMS';
                        break;
                      default:
                        displayName = notifType;
                    }

                    return CheckboxListTile(
                      title: Text(displayName),
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedNotificationTypes.add(notifType);
                          } else {
                            tempSelectedNotificationTypes.remove(notifType);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedNotificationTypes = tempSelectedNotificationTypes;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Takip Ekle'),
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
                        // Başlık Türü (Üste al)
                        _buildFormSection(
                          title: 'Başlık Türü',
                          child: _buildCupertinoField(
                            placeholder: 'Başlık Türü',
                            value: trackingTitles.isEmpty
                                ? 'Başlık türleri yükleniyor...'
                                : (_selectedTitleID == -1
                                    ? null
                                    : (
                                        trackingTitles
                                            .cast<Map<String, Object>>()
                                            .firstWhere(
                                              (t) => t['id'] == _selectedTitleID,
                                              orElse: () => <String, Object>{'name': 'Başlık türü seçiniz'},
                                            )['name'] as String
                                      )
                                  ),
                            onTap: _showTitlePicker,
                            isDisabled: trackingTitles.isEmpty,
                          ),
                          theme: theme,
                        ),

                        // Özel Başlık ("Diğer" seçildiğinde göster)
                        if (_isOtherTitleSelected)
                          _buildFormSection(
                            title: 'Özel Başlık',
                            child: TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              controller: _customTitleController,
                              decoration: _buildInputDecoration(
                                hintText: 'Özel başlık giriniz...',
                              ),
                              validator: (value) {
                                if (_isOtherTitleSelected && (value == null || value.isEmpty)) {
                                  return 'Lütfen özel başlık giriniz';
                                }
                                return null;
                              },
                            ),
                            theme: theme,
                          ),

                        // Açıklama
                        _buildFormSection(
                          title: 'Açıklama',
                          child: TextFormField(
            textCapitalization: TextCapitalization.sentences,
                            controller: _descController,
                            decoration: _buildInputDecoration(
                              hintText: 'Detayları yazınız...',
                            ),
                            maxLines: 4,
                          ),
                          theme: theme,
                        ),

                        // Tip ve Durum
                        _buildFormSection(
                          title: 'Statü',
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tip',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                 _buildCupertinoField(
placeholder: 'Tip',
value: trackingTypes.isEmpty
    ? 'Tipler yükleniyor...'
    : (_selectedTypeID == -1
        ? null
        : (
            trackingTypes
                // (opsiyonel) listedeki map'leri doğru tipe dök
                .cast<Map<String, Object>>()
                .firstWhere(
                  (t) => t['id'] == _selectedTypeID,
                  orElse: () => <String, Object>{'name': 'Tip seçiniz'},
                )['name'] as String
          )
      ),
onTap: _showTypePicker,
isDisabled: trackingTypes.isEmpty,
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
                                    'Durum',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                 _buildCupertinoField(
placeholder: 'Statü',
value: statuses.isEmpty
    ? 'Statüler yükleniyor...'
    : (_selectedStatusID == -1
        ? null
        : (
            statuses
                // (opsiyonel) listedeki map'leri doğru tipe dök
                .cast<Map<String, Object>>()
                .firstWhere(
                  (t) => t['id'] == _selectedStatusID,
                  orElse: () => <String, Object>{'name': 'Statü seçiniz'},
                )['name'] as String
          )
      ),
onTap: _showStatusPicker,
isDisabled: statuses.isEmpty,
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
                                          'Bitiş Tarihi',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCupertinoField(
                                          placeholder: 'DD.MM.YYYY',
                                          value: _dueDateController.text.isEmpty ? null : _dueDateController.text,
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
                                          'Hatırlatma Tarihi',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCupertinoField(
                                          placeholder: 'DD.MM.YYYY',
                                          value: _remindDateController.text.isEmpty ? null : _remindDateController.text,
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

                        // Atanan Kişiler
                      _buildFormSection(
                        title: 'Atanan Kişiler',
                        child: _buildCupertinoField(
                        placeholder: 'Atanan Kişiler',
                        value: users.isEmpty
                            ? 'Kişiler yükleniyor...'
                            : _selectedUserIDs.isEmpty
                              ? null
                              : _selectedUserIDs.map((id) {
                                  final user = users.firstWhere(
                                    (u) => u['id'] == id,
                                    orElse: () => <String, Object>{'name': 'Bilinmeyen'},
                                  );
                                  return user['name'] as String;
                                }).join(', '),
                       onTap: _showUserPicker,
                       isDisabled: users.isEmpty,
                        ),
                      theme: theme,
                      ),

                        // Bildirim Türleri (Opsiyonel)
                        _buildFormSection(
                          title: 'Bildirim Türleri (Opsiyonel)',
                          child: _buildCupertinoField(
                            placeholder: 'Bildirim türleri seçiniz',
                            value: _selectedNotificationTypes.isEmpty
                                ? null
                                : _selectedNotificationTypes.map((type) {
                                    switch (type) {
                                      case 'push':
                                        return 'Bildirim';
                                      case 'email':
                                        return 'E-posta';
                                      case 'sms':
                                        return 'SMS';
                                      default:
                                        return type;
                                    }
                                  }).join(', '),
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
                                label: const Text('Ekle'),
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
