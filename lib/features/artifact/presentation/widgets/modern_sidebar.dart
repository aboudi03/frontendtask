import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'bubble_background.dart';

class ModernSidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback? onClose;
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const ModernSidebar({
    super.key,
    required this.isOpen,
    this.onClose,
    required this.selectedIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isOpen ? 280 : 0,
      child: isOpen
          ? Stack(
              children: [
                // Glassy background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF232526),
                        Color(0xFF181A1B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                // Glassy highlight overlay
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                ),
                // Sidebar content
                BubbleBackground(
                  child: Column(
                    children: [
                  // Header
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Navigation',
                          style: AppTheme.headingSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (onClose != null)
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                            color: AppTheme.textSecondaryColor,
                            tooltip: 'Close',
                          ),
                      ],
                    ),
                  ),
                  
                  // Navigation items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _buildNavItem(
                          icon: Icons.home_rounded,
                          title: 'Dashboard',
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.art_track_rounded,
                          title: 'Artifacts',
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.reviews_rounded,
                          title: 'Reviews',
                          index: 2,
                        ),
                        _buildNavItem(
                          icon: Icons.analytics_rounded,
                          title: 'Analytics',
                          index: 3,
                        ),
                        _buildNavItem(
                          icon: Icons.folder_rounded,
                          title: 'Collections',
                          index: 4,
                        ),
                        _buildNavItem(
                          icon: Icons.people_rounded,
                          title: 'Team',
                          index: 5,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildNavItem(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          index: 6,
                        ),
                        _buildNavItem(
                          icon: Icons.help_rounded,
                          title: 'Help',
                          index: 7,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
   ] ): const SizedBox.shrink(),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected?.call(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected 
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 