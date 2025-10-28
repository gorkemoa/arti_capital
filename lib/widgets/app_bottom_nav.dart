import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleNavBar(
      activeIcons: const [
        _ActiveIcon(icon: Icons.dashboard, label: 'Panel'),
        _ActiveIcon(icon: Icons.assignment, label: 'Projeler'),
        _ActiveIcon(icon: Icons.calendar_month, label: 'Takvim'),
        _ActiveIcon(icon: Icons.assessment, label: 'Destekler'),
        _ActiveIcon(icon: Icons.person, label: 'Profil'),
      ],
      inactiveIcons: const [
        _NavLabel(icon: Icons.dashboard_outlined, label: 'Panel'),
        _NavLabel(icon: Icons.assignment_outlined, label: 'Projeler'),
        _NavLabel(icon: Icons.calendar_month_outlined, label: 'Takvim'),
        _NavLabel(icon: Icons.assessment, label: 'Destekler'),
        _NavLabel(icon: Icons.person_outline, label: 'Profil'),
      ],
      height: 70,
      circleWidth: 70,
      activeIndex: currentIndex,
      onTap: onTap,
      color: theme.colorScheme.surface,
      circleColor: theme.colorScheme.primary,
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
      elevation: 8,
      // ignore: deprecated_member_use
      shadowColor: theme.shadowColor.withOpacity(0.2),
      // ignore: deprecated_member_use
      circleShadowColor: theme.colorScheme.primary.withOpacity(0.4),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface,
        ],
      ),
      circleGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary,
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.8)),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              // ignore: deprecated_member_use
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  const _ActiveIcon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}


