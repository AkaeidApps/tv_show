import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/channel_model.dart';
import '../../../../shared/icons/app_icons.dart';
import '../../../library/providers/library_provider.dart';
import '../../../../shared/widgets/channel_logo.dart';

/// Focus/hover aware tile used in the channel grid. Works with touch, mouse
/// and D-pad (Android TV) input.
///
/// Tap plays the channel, the heart toggles a favourite and a long press saves
/// the channel to the "Saved" tab.
class ChannelCard extends StatefulWidget {
  const ChannelCard({super.key, required this.channel, required this.onTap});

  final ChannelModel channel;
  final VoidCallback onTap;

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _focused = false;
  bool _hovered = false;

  bool get _highlighted => _focused || _hovered;

  void _toggleFavorite() {
    final library = context.read<LibraryProvider>();
    final added = library.toggleFavorite(widget.channel.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            added
                ? '${widget.channel.name} added to favourites'
                : '${widget.channel.name} removed from favourites',
          ),
        ),
      );
  }

  void _toggleSaved() {
    final library = context.read<LibraryProvider>();
    final added = library.toggleSaved(widget.channel.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            added
                ? '${widget.channel.name} saved'
                : '${widget.channel.name} removed from saved',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isFavorite = context.select<LibraryProvider, bool>(
      (library) => library.isFavorite(channel.id),
    );

    return Semantics(
      button: true,
      label: '${channel.name}, ${channel.country}',
      child: AnimatedScale(
        scale: _highlighted ? 1.04 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: _toggleSaved,
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surfaceFor(context),
                    AppTheme.surfaceHighFor(context),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _highlighted
                      ? AppTheme.primary
                      : AppTheme.foregroundFor(context).withValues(alpha: 0.08),
                  width: _highlighted ? 1.5 : 1,
                ),
                boxShadow: _highlighted
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                // A slightly brighter plate keeps dark or
                                // transparent logos visible on the dark card.
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.foregroundFor(context)
                                        .withValues(alpha: 0.12),
                                    AppTheme.foregroundFor(context)
                                        .withValues(alpha: 0.03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.foregroundFor(context)
                                      .withValues(alpha: 0.06),
                                ),
                              ),
                              child: ChannelLogo(channel: channel),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _FavoriteButton(
                              isFavorite: isFavorite,
                              onPressed: _toggleFavorite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.foregroundFor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.live,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppTheme.live,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            channel.country.isEmpty
                                ? 'INT'
                                : channel.country.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.mutedForegroundFor(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: AppIcon(
            isFavorite ? AppIcons.favorite : AppIcons.favoriteBorder,
            size: 16,
            color: isFavorite
                ? AppTheme.accent
                : AppTheme.foregroundFor(context).withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
