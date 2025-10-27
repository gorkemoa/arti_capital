import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/projects_service.dart';
import '../theme/app_colors.dart';

class AddInformationView extends StatefulWidget {
  final int projectID;
  final RequiredInfo requiredInfo;

  const AddInformationView({
    super.key,
    required this.projectID,
    required this.requiredInfo,
  });

  @override
  State<AddInformationView> createState() => _AddInformationViewState();
}

class _AddInformationViewState extends State<AddInformationView> {
  final ProjectsService _service = ProjectsService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _valueController;
  late TextEditingController _descController;
  String? _selectedOption;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.requiredInfo.defaultValue);
    _descController = TextEditingController();
    
    // Eğer select tipiyse ve default value varsa
    if (widget.requiredInfo.infoType == 'select' && 
        widget.requiredInfo.defaultValue.isNotEmpty &&
        widget.requiredInfo.options.contains(widget.requiredInfo.defaultValue)) {
      _selectedOption = widget.requiredInfo.defaultValue;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate()) return;

    // Select tipinde seçim yapılmadıysa
    if (widget.requiredInfo.infoType == 'select' && _selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir seçenek seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final infoValue = widget.requiredInfo.infoType == 'select' 
          ? _selectedOption! 
          : _valueController.text.trim();

      final response = await _service.addProjectInformation(
        appID: widget.projectID,
        infoID: widget.requiredInfo.infoID,
        infoValue: infoValue,
        infoDesc: _descController.text.trim(),
      );

      if (mounted) {
        setState(() => _loading = false);

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Bilgi başarıyla eklendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Bilgi eklenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
        title: const Text('Bilgi Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bilgi Adı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconForType(widget.requiredInfo.infoType),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.requiredInfo.infoName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTypeLabel(widget.requiredInfo.infoType),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.requiredInfo.isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Zorunlu',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input alanı (tip bazlı)
              _buildInputField(theme),

              const SizedBox(height: 16),

              // Açıklama alanı
              TextFormField(
            textCapitalization: TextCapitalization.sentences,
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (İsteğe Bağlı)',
                  hintText: 'Ek açıklama girebilirsiniz',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.onSurface.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveInformation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme) {
    switch (widget.requiredInfo.infoType) {
      case 'text':
        return TextFormField(
            textCapitalization: TextCapitalization.sentences,
          controller: _valueController,
          decoration: InputDecoration(
            labelText: '${widget.requiredInfo.infoName} *',
            hintText: widget.requiredInfo.infoName,
            prefixIcon: const Icon(Icons.text_fields),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.onSurface.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (widget.requiredInfo.isRequired && 
                (value == null || value.trim().isEmpty)) {
              return 'Bu alan zorunludur';
            }
            return null;
          },
        );

      case 'textarea':
        return TextFormField(
            textCapitalization: TextCapitalization.sentences,
          controller: _valueController,
          decoration: InputDecoration(
            labelText: '${widget.requiredInfo.infoName} *',
            hintText: widget.requiredInfo.infoName,
            prefixIcon: const Icon(Icons.notes),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.onSurface.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          validator: (value) {
            if (widget.requiredInfo.isRequired && 
                (value == null || value.trim().isEmpty)) {
              return 'Bu alan zorunludur';
            }
            return null;
          },
        );

      case 'select':
        return DropdownButtonFormField<String>(
          value: _selectedOption,
          decoration: InputDecoration(
            labelText: '${widget.requiredInfo.infoName} *',
            prefixIcon: const Icon(Icons.list),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.onSurface.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          items: widget.requiredInfo.options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOption = value;
            });
          },
          validator: (value) {
            if (widget.requiredInfo.isRequired && value == null) {
              return 'Lütfen bir seçenek seçin';
            }
            return null;
          },
        );

      default:
        return TextFormField(
            textCapitalization: TextCapitalization.sentences,
          controller: _valueController,
          decoration: InputDecoration(
            labelText: widget.requiredInfo.infoName,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'textarea':
        return Icons.notes;
      case 'select':
        return Icons.list;
      default:
        return Icons.info_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Metin Alanı';
      case 'textarea':
        return 'Çok Satırlı Metin';
      case 'select':
        return 'Seçim Listesi';
      default:
        return type;
    }
  }
}
