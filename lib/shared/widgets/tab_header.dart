import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../icons/app_icons.dart';

/// Gradient icon + title header shared by every tab.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = AppTheme.brandGradient,
    this.action,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Gradient gradient;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppIcon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.foregroundFor(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.mutedForegroundFor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
