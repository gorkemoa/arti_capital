import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/company_models.dart';
import '../services/general_service.dart';
import '../services/storage_service.dart';
import '../services/company_service.dart';
import '../theme/app_colors.dart';

class AddCompanyDocumentView extends StatefulWidget {
  const AddCompanyDocumentView({super.key, required this.compId});
  final int compId;

  @override
  State<AddCompanyDocumentView> createState() => _AddCompanyDocumentViewState();
}

class _AddCompanyDocumentViewState extends State<AddCompanyDocumentView> {
  List<DocumentTypeItem> _documentTypes = [];
  DocumentTypeItem? _selectedType;
  PlatformFile? _pickedFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await GeneralService().getDocumentTypes();
    if (!mounted) return;
    setState(() {
      _documentTypes = types;
      if (types.isNotEmpty) _selectedType = types.first;
    });
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
    if (res == null || res.files.isEmpty) return;
    setState(() {
      _pickedFile = res.files.first;
    });
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }

  Future<void> _submit() async {
    if (_selectedType == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge türü ve dosya seçin')));
      return;
    }

    final token = await StorageService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oturum bulunamadı')));
      return;
    }

    setState(() { _submitting = true; });
    try {
      final file = _pickedFile!;
      final String? path = file.path;
      final bytes = file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
      if (bytes == null) throw Exception('Dosya okunamadı');
      final mime = _guessMime(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final ok = await const CompanyService().addCompanyDocument(
        userToken: token,
        compId: widget.compId,
        documentType: _selectedType!.documentID,
        dataUrl: dataUrl,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge başarıyla eklendi.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge eklenemedi')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belge Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<DocumentTypeItem>(
              value: _selectedType,
              items: _documentTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.documentName)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
              decoration: const InputDecoration(labelText: 'Belge Türü'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_pickedFile == null ? 'Dosya Seç' : _pickedFile!.name),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Yükle'),
            ),
          ],
        ),
      ),
    );
  }
}


