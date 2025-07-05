import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'bubble_background.dart';

class ModernNavbar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSettingsPressed;

  const ModernNavbar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BubbleBackground(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Menu button
            if (onMenuPressed != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu_rounded),
                  color: Colors.white,
                  tooltip: 'Menu',
                ),
              ),

            const SizedBox(width: 16),

            // App title
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.art_track_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: AppTheme.headingMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              children: [
                // Search button
                if (onSearchPressed != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: onSearchPressed,
                      icon: const Icon(Icons.search_rounded),
                      color: Colors.white,
                      tooltip: 'Search',
                    ),
                  ),

                const SizedBox(width: 8),

                // Settings button
                if (onSettingsPressed != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: onSettingsPressed,
                      icon: const Icon(Icons.settings_rounded),
                      color: Colors.white,
                      tooltip: 'Settings',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 