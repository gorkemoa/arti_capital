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
  
  int _selectedTypeID = 1;
  int _selectedStatusID = 1;
  int _selectedUserID = 1;
  String? _selectedNotificationType;
  bool _isLoading = false;

  // Notification type options
  final List<String> _notificationTypes = ['push', 'email', 'sms', 'all'];

  // Mock data for dropdowns
  List<Map<String, dynamic>> trackingTypes = [];

  List<Map<String, dynamic>> statuses = [];

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _dueDateController = TextEditingController();
    _remindDateController = TextEditingController();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final fetchedTypes = await _service.getFollowupTypes();
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
          
          statuses = fetchedStatuses
              .map((status) => {
                    'id': status.statusID,
                    'name': status.statusName,
                    'color': status.statusColor,
                  })
              .toList();
          
          users = fetchedPersons;
          
          // Set default values if data loaded
          if (trackingTypes.isNotEmpty) {
            _selectedTypeID = trackingTypes[0]['id'] as int;
          }
          if (statuses.isNotEmpty) {
            _selectedStatusID = statuses[0]['id'] as int;
          }
          if (users.isNotEmpty) {
            _selectedUserID = users[0]['id'] as int;
          }
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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.addTracking(
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
                                  ? 'Bildirim'
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
                        // Başlık
                        _buildFormSection(
                          title: 'Başlık',
                          child: TextFormField(
            textCapitalization: TextCapitalization.sentences,
                            controller: _titleController,
                            decoration: _buildInputDecoration(
                              hintText: 'Örn: Müşteri görüşmesi',
                            ),
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
    : (
        trackingTypes
            // (opsiyonel) listedeki map'leri doğru tipe dök
            .cast<Map<String, Object>>()
            .firstWhere(
              (t) => t['id'] == _selectedTypeID,
              orElse: () => <String, Object>{'name': 'Tip seçiniz'},
            )['name'] as String
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
    : (
        statuses
            // (opsiyonel) listedeki map'leri doğru tipe dök
            .cast<Map<String, Object>>()
            .firstWhere(
              (t) => t['id'] == _selectedStatusID,
              orElse: () => <String, Object>{'name': 'Statü seçiniz'},
            )['name'] as String
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

                        // Atanan Kişi
                      _buildFormSection(
                        title: 'Atanan Kişi',
                        child: _buildCupertinoField(
                        placeholder: 'Atanan Kişi',
                        value: users.isEmpty
                            ? 'Kişiler yükleniyor...'
                            : (
                              users
                              .cast<Map<String, Object>>() // listeyi hizala
                              .firstWhere(
                              (u) => u['id'] == _selectedUserID,
                              orElse: () => const <String, Object>{'name': 'Kişi seçiniz'},
                              )['name'] as String
                              ),
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
                            value: _selectedNotificationType == null
                                ? null
                                : (_selectedNotificationType == 'push'
                                    ? 'Bildirim'
                                    : _selectedNotificationType == 'email'
                                        ? 'E-posta'
                                        : _selectedNotificationType == 'sms'
                                            ? 'SMS'
                                            : 'Tümü'),
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
