import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/line_color_service.dart';

/// Extracted widget for the Favorites Dashboard following Flutter Expert guidelines.
/// Uses const constructor and is a separate StatelessWidget for optimization.
class FavoritesDashboard extends StatelessWidget {
  final List<FavoriteItem> favorites;
  final Map<String, Estimation?> estimations;
  final DateTime? lastUpdateTime;
  final VoidCallback onRefresh;
  final Future<void> Function(String lineId, String stopId) onRemove;

  const FavoritesDashboard({
    super.key,
    required this.favorites,
    required this.estimations,
    required this.lastUpdateTime,
    required this.onRefresh,
    required this.onRemove,
  });

  String _formatLastUpdate(AppLocalizations l10n) {
    if (lastUpdateTime == null) return '';
    final h = lastUpdateTime!.hour.toString().padLeft(2, '0');
    final m = lastUpdateTime!.minute.toString().padLeft(2, '0');
    final s = lastUpdateTime!.second.toString().padLeft(2, '0');
    return '${l10n.lastUpdate}: $h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noStopsFound),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Last update time banner
        if (lastUpdateTime != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFE8F5E9)
                : const Color(0xFF1B5E20),
            child: Center(
              child: Text(
                _formatLastUpdate(l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF2E7D32)
                      : Colors.white70,
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final est = estimations[fav.key];

                return _FavoriteCard(
                  favorite: fav,
                  estimation: est,
                  onRemove: () => onRemove(fav.lineId, fav.stopId),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual favorite card widget
class _FavoriteCard extends StatelessWidget {
  final FavoriteItem favorite;
  final Estimation? estimation;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.favorite,
    required this.estimation,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Line Icon
            CircleAvatar(
              radius: 24,
              backgroundColor: LineColorService.getColor(favorite.lineId),
              foregroundColor: Colors.white,
              child: Text(
                favorite.lineId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            // Stop and Line Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.stopLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    favorite.lineLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Estimations
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  estimation?.nextBus ?? '...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: (estimation?.nextBus.contains('min') == true ||
                            estimation?.nextBus == 'ahora' ||
                            estimation?.nextBus == 'now')
                        ? Colors.green[700]
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (estimation?.followingBus != null && estimation!.followingBus != '-')
                  Text(
                    estimation!.followingBus,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
