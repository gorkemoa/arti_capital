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
  bool _isCompNotification = true;
  bool _isLoading = false;

  // Mock data for dropdowns
  List<Map<String, dynamic>> trackingTypes = [];

  List<Map<String, dynamic>> statuses = [];

  final List<Map<String, dynamic>> users = [
    {'id': 1, 'name': 'Benim Adım'},
    {'id': 2, 'name': 'Kullanıcı 2'},
    {'id': 3, 'name': 'Kullanıcı 3'},
  ];

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
          
          // Set default values if data loaded
          if (trackingTypes.isNotEmpty) {
            _selectedTypeID = trackingTypes[0]['id'] as int;
          }
          if (statuses.isNotEmpty) {
            _selectedStatusID = statuses[0]['id'] as int;
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd.MM.yyyy').format(picked);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
        isCompNotification: _isCompNotification ? 1 : 0,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Durumu Ekle'),
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
                  // Proje Bilgisi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proje Durumu Ekle',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.projectTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                                      'Tip *',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    trackingTypes.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.onSurface.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.onSurface.withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Tipler yükleniyor...',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: AppColors.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                          )
                                        : _buildCupertinoField(
                                            placeholder: 'Tip seçin',
                                            value: trackingTypes
                                                .firstWhere(
                                                  (t) => t['id'] == _selectedTypeID,
                                                  orElse: () => {},
                                                )['name'] as String?,
                                            onTap: _showTypePicker,
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
                                      'Durum *',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    statuses.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.onSurface.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.onSurface.withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Statüsler yükleniyor...',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: AppColors.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                          )
                                        : _buildCupertinoField(
                                            placeholder: 'Durum seçin',
                                            value: statuses
                                                .firstWhere(
                                                  (s) => s['id'] == _selectedStatusID,
                                                  orElse: () => {},
                                                )['name'] as String?,
                                            onTap: _showStatusPicker,
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
                                        TextFormField(
                                          controller: _dueDateController,
                                          readOnly: true,
                                          decoration: _buildInputDecoration(
                                            hintText: 'DD.MM.YYYY',
                                            suffixIcon: Icons.calendar_today,
                                          ),
                                          onTap: () => _selectDate(_dueDateController),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Bitiş tarihi gereklidir';
                                            }
                                            return null;
                                          },
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
                                        TextFormField(
                                          controller: _remindDateController,
                                          readOnly: true,
                                          decoration: _buildInputDecoration(
                                            hintText: 'DD.MM.YYYY',
                                            suffixIcon: Icons.calendar_today,
                                          ),
                                          onTap: () => _selectDate(_remindDateController),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Hatırlatma tarihi gereklidir';
                                            }
                                            return null;
                                          },
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
                          child: DropdownButtonFormField<int>(
                            value: _selectedUserID,
                            decoration: _buildInputDecoration(),
                            items: users
                                .map<DropdownMenuItem<int>>((user) => DropdownMenuItem<int>(
                                      value: user['id'] as int,
                                      child: Text(user['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserID = value ?? 1;
                              });
                            },
                          ),
                          theme: theme,
                        ),

                        // Firma Bilgilendirme
                        _buildFormSection(
                          title: 'Bildirimler',
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.onSurface.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.onSurface.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isCompNotification,
                                  onChanged: (value) {
                                    setState(() {
                                      _isCompNotification = value ?? true;
                                    });
                                  },
                                  fillColor: MaterialStateProperty.resolveWith((states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return Colors.grey;
                                  }),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Firmayı Bilgilendir',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Firma bu durumu e-posta ile alacak',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildCupertinoField({
    required String placeholder,
    String? value,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled 
              ? AppColors.onSurface.withOpacity(0.02)
              : AppColors.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value == null || value.isEmpty ? placeholder : value,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (value == null || value.isEmpty)
                      ? AppColors.onSurface.withOpacity(isDisabled ? 0.4 : 0.6)
                      : AppColors.onSurface.withOpacity(isDisabled ? 0.5 : 1),
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
                  children: trackingTypes
                      .map((type) => Center(child: Text(type['name'] as String)))
                      .toList(),
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
                  children: statuses
                      .map((status) => Center(
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
}
