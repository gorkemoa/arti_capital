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
        Icon(Icons.dashboard, color: Colors.white),
        Icon(Icons.assignment, color: Colors.white),
        Icon(Icons.assessment, color: Colors.white),
        Icon(Icons.person, color: Colors.white),
      ],
      inactiveIcons: const [
        _NavLabel(icon: Icons.dashboard_outlined, label: 'Panel'),
        _NavLabel(icon: Icons.assignment_outlined, label: 'Talepler'),
        _NavLabel(icon: Icons.assessment, label: 'Destekler'),
        _NavLabel(icon: Icons.person_outline, label: 'Profil'),
      ],
      height: 76,
      circleWidth: 60,
      activeIndex: currentIndex,
      onTap: onTap,
      color: theme.colorScheme.surface,
      circleColor: theme.colorScheme.primary,
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
      elevation: 8,
      shadowColor: theme.shadowColor.withOpacity(0.2),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.8)),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


