import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/documents_models.dart';
import '../models/company_models.dart';
import 'document_preview_view.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  late Future<GetMyDocumentsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = UserService().getMyDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
          title: Text('Belgelerim', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
          bottom: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Firma Belgeleri'),
              Tab(text: 'Ortak Belgeleri'),
            ],
          ),
        ),
        body: FutureBuilder<GetMyDocumentsResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final res = snapshot.data!;
          if (res.error || !res.success) {
            return Center(child: Text(res.errorMessage ?? 'Bir hata oluştu'));
          }

            final List<DocumentsGroupItem> compGroups = res.compDocs;
            final List<DocumentsGroupItem> userGroups = res.userDocs;

            Widget buildTabContent(List<DocumentsGroupItem> groups, {required String emptyText, required IconData icon}) {
              if (groups.isEmpty) {
                return Center(child: Text(emptyText, style: theme.textTheme.bodyMedium));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Panel(
                    title: '',
                    icon: icon,
                    children: [
                      for (int i = 0; i < groups.length; i++) ...[
                        _GroupPanel(group: groups[i]),
                        if (i != groups.length - 1)
                          Divider(height: 16, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.12)),
                      ],
                    ],
                  ),
                ],
              );
            }

            return TabBarView(
              children: [
                buildTabContent(
                  compGroups,
                  emptyText: 'Firma belgesi bulunmuyor',
                  icon: Icons.apartment_outlined,
                ),
                buildTabContent(
                  userGroups,
                  emptyText: 'Henüz yüklediğiniz belge bulunmuyor',
                  icon: Icons.person_outline,
                ),
              ],
            );
        },
        ),
      ),
    );
  }
}

class _GroupPanel extends StatelessWidget {
  const _GroupPanel({required this.group});
  final DocumentsGroupItem group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    final muted = theme.colorScheme.onSurface.withOpacity(0.7);
    final title = group.companyName.isEmpty ? 'Kullanıcı Belgeleri' : group.companyName;
    final subtitle = group.companyType;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.apartment_outlined, size: 18, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                if (group.documents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Belge yok', style: theme.textTheme.bodySmall),
                  )
                else
                  for (int i = 0; i < group.documents.length; i++) ...[
                    _DocumentTile(doc: group.documents[i]),
                    if (i != group.documents.length - 1)
                      Divider(height: 12, thickness: 0.5, color: border),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc});
  final CompanyDocumentItem doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(doc.documentType, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(doc.createDate, style: theme.textTheme.bodySmall),
      leading: Icon(Icons.description_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.open_in_new, color: theme.colorScheme.onPrimary, size: 16),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentPreviewView(
              url: doc.documentURL,
              title: doc.documentType,
            ),
          ),
        );
      },
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withOpacity(0.12);
    final muted = theme.colorScheme.onSurface.withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: border),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

