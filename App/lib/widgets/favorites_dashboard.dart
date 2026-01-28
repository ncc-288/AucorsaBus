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
  final Future<void> Function(FavoriteItem item) onUpdate;

  const FavoritesDashboard({
    super.key,
    required this.favorites,
    required this.estimations,
    required this.lastUpdateTime,
    required this.onRefresh,
    required this.onRemove,
    required this.onUpdate,
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
                  key: ValueKey(fav.key), // Proper key for list items
                  favorite: fav,
                  estimation: est,
                  onRemove: () => onRemove(fav.lineId, fav.stopId),
                  onUpdate: onUpdate,
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
  final Future<void> Function(FavoriteItem item) onUpdate;

  const _FavoriteCard({
    super.key,
    required this.favorite,
    required this.estimation,
    required this.onRemove,
    required this.onUpdate,
  });

  void _showEditDialog(BuildContext context) {
    final stopController = TextEditingController(text: favorite.customStopName ?? favorite.stopLabel);
    final lineController = TextEditingController(text: favorite.customLineName ?? favorite.lineLabel);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editFavorite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
               controller: stopController,
               decoration: InputDecoration(
                 labelText: l10n.stopName,
                 hintText: favorite.stopLabel,
               ),
             ),
             const SizedBox(height: 16),
             TextField(
               controller: lineController,
               decoration: InputDecoration(
                 labelText: l10n.lineName,
                 hintText: favorite.lineLabel,
               ),
             ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newStopName = stopController.text.trim();
              final newLineName = lineController.text.trim();
              
              final updated = FavoriteItem(
                stopId: favorite.stopId,
                stopLabel: favorite.stopLabel,
                lineId: favorite.lineId,
                lineLabel: favorite.lineLabel,
                customStopName: newStopName.isNotEmpty && newStopName != favorite.stopLabel ? newStopName : null,
                customLineName: newLineName.isNotEmpty && newLineName != favorite.lineLabel ? newLineName : null,
              );
              
              onUpdate(updated);
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which line label to show: Custom > API Estimation > Stored Original
    final displayLineLabel = favorite.customLineName ?? 
                             estimation?.lineName ?? 
                             favorite.lineLabel;

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
                    favorite.customStopName ?? favorite.stopLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayLineLabel,
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
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit', 
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onRemove,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
