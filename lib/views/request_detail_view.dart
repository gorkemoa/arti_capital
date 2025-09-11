import 'package:flutter/material.dart';

class RequestDetailView extends StatelessWidget {
  const RequestDetailView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        title: Text('Başvuru Detayı', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) .copyWith(color: colorScheme.onPrimary)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeaderCard(title: title),
          const SizedBox(height: 16),
          _SectionTitle('Zaman Çizelgesi'),
          const SizedBox(height: 12),
          const _TimelineItems(),
          const SizedBox(height: 16),
          _SectionTitle('Belgeler'),
          const SizedBox(height: 12),
          const _DocumentsList(),
          const SizedBox(height: 16),
          _SectionTitle('Bildirimler'),
          const SizedBox(height: 12),
          const _NotificationCard(),
          const SizedBox(height: 16),
          _AdvisorCard(
            name: 'Ayşe Yılmaz',
            email: 'destek@articapital.com',
          ),
          const SizedBox(height: 16),
          _SectionTitle('Hızlı Aksiyonlar'),
          const SizedBox(height: 12),
          const _QuickActions(),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_outlined, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Başvuru Onaylandı',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Başvuru İlerlemesi', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _SegmentedProgress(total: 4, completed: 3),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Center(child: _StepLabel('Başvuru', true))),
              Expanded(child: Center(child: _StepLabel('Değerlendirme', true))),
              Expanded(child: Center(child: _StepLabel('Onay', false))),
              Expanded(child: Center(child: _StepLabel('Tamamlandı', false))),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _StepLabel(String text, bool active) {
  return Opacity(
    opacity: active ? 1 : 0.6,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      textAlign: TextAlign.center,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.total, required this.completed});
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int clampedCompleted = completed.clamp(0, total);
    return Row(
      children: List.generate(total * 2 - 1, (index) {
        final bool isDivider = index.isOdd;
        if (isDivider) {
          return SizedBox(width: 4);
        }
        final int segIndex = index ~/ 2;
        final bool active = segIndex < clampedCompleted;
        return Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: active ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _TimelineItems extends StatelessWidget {
  const _TimelineItems();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineTile(icon: Icons.check_circle, title: 'Başvuru Gönderildi', subtitle: '15 Nisan 2024', color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        _TimelineTile(icon: Icons.check_circle, title: 'Belgeler İncelendi', subtitle: '18 Nisan 2024', color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        _TimelineTile(icon: Icons.hourglass_top, title: 'Değerlendirme', subtitle: 'Devam ediyor', color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentsList extends StatelessWidget {
  const _DocumentsList();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        _docRow(context, Icons.task_alt, 'Proje Planı', 'Görüntüle', colorScheme.primary),
        const SizedBox(height: 10),
        _docRow(context, Icons.warning_amber_rounded, 'Faaliyet Raporu (Eksik)', 'Yükle', colorScheme.primary),
      ],
    );
  }

  Widget _docRow(BuildContext context, IconData icon, String title, String action, Color actionColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: icon == Icons.warning_amber_rounded
                ? colorScheme.onSurface.withOpacity(0.8)
                : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: actionColor),
            child: Text(action, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"Değerlendirme toplantısı için 20 Mayıs 2024 tarihini takviminize eklemeyi unutmayın."',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text('Arti Capital · 19 Nisan 2024', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({required this.name, required this.email});
  final String name;
  final String email;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _InitialsAvatar(name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(email, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.75))),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.mail_outline, onTap: () {}),
          const SizedBox(width: 8),
          _RoundIconButton(icon: Icons.call_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  String _initialsOf(String fullName) {
    final parts = fullName.trim().split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    final first = parts.first.characters.first.toString();
    final last = parts.last.characters.first.toString();
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _initialsOf(name);
    return CircleAvatar(
      radius: 28,
      backgroundColor: colorScheme.primary.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.file_upload_outlined,
            title: 'Belge Yükle',
            color: colorScheme.primary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.send_outlined,
            title: 'Mesaj Gönder',
            color: colorScheme.primary,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}


