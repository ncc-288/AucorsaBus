import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Gmail-style floating search bar widget.
/// Icon (menu/back) is OUTSIDE the pill, pill contains search hint and icon.
class FloatingSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onLeadingTap;
  final IconData leadingIcon;

  const FloatingSearchBar({
    super.key,
    required this.onTap,
    this.onLeadingTap,
    this.leadingIcon = Icons.menu,
  });

  /// Factory for use on detail screens with back arrow
  const FloatingSearchBar.withBackButton({
    super.key,
    required this.onTap,
    required this.onLeadingTap,
  }) : leadingIcon = Icons.arrow_back;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Leading icon (Menu or Back) - OUTSIDE the pill
          IconButton(
            icon: Icon(leadingIcon),
            onPressed: onLeadingTap,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          // Pill-shaped search bar
          Expanded(
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(28),
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Search text
                      Expanded(
                        child: Text(
                          l10n.searchHint,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ),
                      // Search icon
                      Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
