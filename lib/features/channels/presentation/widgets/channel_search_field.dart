import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/icons/app_icons.dart';

/// Rounded search field used by the Home and Sports tabs.
class ChannelSearchField extends StatelessWidget {
  const ChannelSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search channels, countries or categories',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: AppTheme.foregroundFor(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.mutedForegroundFor(context),
            fontSize: 14,
          ),
          prefixIcon: AppIcon(
            AppIcons.search,
            color: AppTheme.mutedForegroundFor(context),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const AppIcon(AppIcons.close, size: 18),
                  color: AppTheme.mutedForegroundFor(context),
                ),
          filled: true,
          fillColor: AppTheme.surfaceFor(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.foregroundFor(context).withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}
