// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
// Toolbar ayrı pakette değil; 11.x ile ana pakette. Ayrı importu kaldırıyoruz.
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../services/contact_service.dart';
import '../models/user_request_models.dart';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  String? _selectedRequestType;
  List<ContactSubjectItem> _subjectItems = [];
  List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _loadSubjects();
  }

  Future<void> _showSubjectPicker() async {
    if (_subjectItems.isEmpty) return;
    int initialIndex = 0;
    if (_selectedRequestType != null) {
      final idx = _subjectItems.indexWhere((e) => e.subjectTitle == _selectedRequestType);
      if (idx >= 0) initialIndex = idx;
    }
    int currentIndex = initialIndex.clamp(0, _subjectItems.length - 1);

    await showCupertinoModalPopup(
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
                    Text('Talep Türü Seçiniz', style: Theme.of(context).textTheme.titleMedium),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('Seç'),
                      onPressed: () {
                        setState(() {
                          _selectedRequestType = _subjectItems[currentIndex].subjectTitle;
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
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: currentIndex),
                  onSelectedItemChanged: (idx) { currentIndex = idx; },
                  children: _subjectItems.isEmpty
                      ? [const Text('-')]
                      : _subjectItems.map((e) => Center(child: Text(e.subjectTitle))).toList(),
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
    final colorScheme = theme.colorScheme;
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('İletişim'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Bize Ulaşın', style: theme.textTheme.titleMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Herhangi bir sorunuz veya talebiniz varsa, lütfen aşağıdaki formu doldurun veya doğrudan iletişime geçin.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.85), height: 1.5),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              children: [
               
                // Talep türü seçimi
                if (_subjectItems.isNotEmpty)
                  GestureDetector(
                    onTap: _showSubjectPicker,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedRequestType == null || _selectedRequestType!.isEmpty
                                  ? 'Talep türü seçiniz'
                                  : _selectedRequestType!,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: (_selectedRequestType == null || _selectedRequestType!.isEmpty)
                                    ? colorScheme.onSurface.withOpacity(0.6)
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_down, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                const SizedBox(height: 10),
                // Konu alanı
                _InputField(controller: _subjectCtrl, hint: 'Konu'),
                const SizedBox(height: 10),
                // Zengin metin editörü
                _RichMessageField(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                ),
                const SizedBox(height: 10),
                // Dosya ekleme alanı
                _AttachmentField(
                  files: _attachments,
                  onAdd: _pickFiles,
                  onRemove: (i) => setState(() => _attachments.removeAt(i)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Gönder', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: subtleBorder),
          const SizedBox(height: 16),
          Text('Sıkça Sorulan Sorular', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _FaqTile(
            title: 'Hibe ve Teşvikler Hakkında',
            body:
                'Hibe; geri ödemesiz, teşvik ise belirli şartlarda geri ödemeli ya da vergisel avantajlar içeren destek türleridir. Başlıca destek kalemleri; ekipman/makine alımı, yazılım-lisans, eğitim ve danışmanlık giderleri, belgelendirme ve test-sertifikasyon masraflarıdır. Programların kapsamı kurumlara (KOSGEB, TÜBİTAK, Sanayi ve Teknoloji Bakanlığı vb.) göre değişir.',
          ),
          _FaqTile(
            title: 'Başvuru Süreci',
            body:
            
                'Standart süreç şu adımlardan oluşur: (1) Uygun program tespiti, (2) Proje kapsamının ve bütçenin hazırlanması, (3) Gerekli evrakların derlenmesi ve çevrimiçi başvuru, (4) Değerlendirme ve revizyon süreci, (5) Onay sonrası sözleşme ve harcama/raporlama dönemi. Ortalama değerlendirme süresi programlara göre 4–12 hafta arasında değişebilir.',
          ),
          _FaqTile(
            title: 'Üretim Teşvikleri',
            body:
                'Yatırım teşvikleri; gümrük vergisi muafiyeti, KDV istisnası, vergi indirimi, SGK işveren hissesi desteği ve faiz/döviz kredisi desteği gibi bileşenler sunabilir. Bölge ve ölçek bazlı farklılıklar olur. Otomasyon, verimlilik artırıcı yatırımlar ve yeşil dönüşüm projeleri önceliklendirilmektedir.',
          ),
        ],
      ),
    );
  }

  void _submit() {
    final plain = _quillController.document.toPlainText().trim();
    final token = StorageService.getToken();
    final selectedId = (_subjectItems.isNotEmpty && _selectedRequestType != null)
        ? _subjectItems
            .firstWhere((e) => e.subjectTitle == _selectedRequestType, orElse: () => ContactSubjectItem(subjectID: 0, subjectTitle: ''))
            .subjectID
        : 0;
    final req = SendContactMessageRequest(
      userToken: token ?? '',
      subject: selectedId,
      message: plain,
    );

    ContactService().sendContactMessage(req).then((resp) {
      if (resp.success) {
        final msg = resp.successMessage ?? 'Mesajınız başarıyla gönderildi.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _nameCtrl.clear();
        _surnameCtrl.clear();
        _emailCtrl.clear();
        _phoneCtrl.clear();
        _subjectCtrl.clear();
        setState(() {
          _quillController = quill.QuillController.basic();
          _selectedRequestType = null;
          _attachments = [];
        });
      } else {
        final msg = resp.errorMessage ?? 'Mesaj gönderilemedi.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }).catchError((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bir hata oluştu. Lütfen tekrar deneyin.')));
    });
  }

  Future<void> _loadSubjects() async {
    try {
      final resp = await ContactService().getContactSubjects();
      if (resp.success && resp.subjects.isNotEmpty) {
        setState(() {
          _subjectItems = resp.subjects;
          _selectedRequestType = null; // Başlangıçta seçili olmasın, placeholder görünsün
        });
      }
    } finally {
      // no-op
    }
  }


  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachments.addAll(result.files);
      });
    }
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: 1,
      minLines: 1,
      style: theme.textTheme.bodyMedium,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.8), width: 1.4)),
      ),
    );
  }
}

// ignore: unused_element
class _RequestTypeField extends StatelessWidget {
  const _RequestTypeField({required this.items, required this.value, required this.onChanged});
  final List<ContactSubjectItem> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtle = colorScheme.onSurface.withOpacity(0.12);
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(value: e.subjectTitle, child: Text(e.subjectTitle, style: theme.textTheme.bodyMedium)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Talep türü seçin',
        hintStyle: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: subtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: subtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.8), width: 1.4)),
      ),
    );
  }
}

class _RichMessageField extends StatelessWidget {
  const _RichMessageField({required this.controller, required this.focusNode});
  final quill.QuillController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zengin metin araç çubuğu (toolbar) bu sürümde kaldırıldı.
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            border: Border.all(color: subtleBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: quill.QuillEditor.basic(controller: controller),
        ),
      ],
    );
  }
}

class _AttachmentField extends StatelessWidget {
  const _AttachmentField({required this.files, required this.onAdd, required this.onRemove});
  final List<PlatformFile> files;
  final Future<void> Function() onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.attach_file),
                label: const Text('Belge / Dosya Ekle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < files.length; i++)
                  Chip(
                    label: Text(files[i].name, style: theme.textTheme.bodySmall),
                    onDeleted: () => onRemove(i),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          collapsedIconColor: colorScheme.onSurface,
          iconColor: colorScheme.onSurface,
          title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.85), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


