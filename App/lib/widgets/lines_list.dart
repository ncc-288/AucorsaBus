import 'package:flutter/material.dart';
import '../models/models.dart';
import '../screens/line_detail_screen.dart';
import '../services/line_color_service.dart';

/// Extracted widget for the Lines list following Flutter Expert guidelines.
/// Uses const constructor and is a separate StatelessWidget for optimization.
class LinesList extends StatelessWidget {
  final List<BusLine> lines;
  final String? errorMessage;

  const LinesList({
    super.key,
    required this.lines,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty && errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final displayId = line.label.split('ㅤ')[0].trim();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: LineColorService.getColor(displayId),
              foregroundColor: Colors.white,
              child: Text(
                displayId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              (line.label.contains('ㅤ')
                      ? line.label.substring(line.label.indexOf('ㅤ') + 1)
                      : line.label)
                  .trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LineDetailScreen(line: line),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
