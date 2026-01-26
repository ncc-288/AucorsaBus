import 'package:flutter/material.dart';

class LineColorService {
  static const Map<String, Color> _lineColors = {
    '1': Color(0xFF006837),   // Green
    '2': Color(0xFFED1C24),   // Red
    '3': Color(0xFF92278F),   // Purple
    '4': Color(0xFFF06EA9),   // Pinkish
    '5': Color(0xFF003F87),   // Dark Blue
    '6': Color(0xFF6DCFF6),   // Cyan / Light Blue 
    '7': Color(0xFFF26522),   // Orange
    '8': Color(0xFFFFF200),   // Yellow
    '9': Color(0xFFD4145A),   // Magenta
    '10': Color(0xFFD9E021),  // Lime Yellow
    '11': Color(0xFF0071BC),  // Blue
    '12': Color(0xFF39B54A),  // Green
    '13': Color(0xFF9E6B30),  // Brownish
    '14': Color(0xFF582C12),  // Dark Brown
    '46': Color(0xFFF7941D),  // Orange
    '71': Color(0xFF58595B),  // Grey
    '72': Color(0xFFD4145A),  // Magenta
    '73': Color(0xFFF7941D),  // Orange
    '74': Color(0xFF39B54A),  // Green
    '75': Color(0xFF0071BC),  // Blue
    '76': Color(0xFFF26522),  // Orange
    '78': Color(0xFF00A99D),  // Teal
    'O1': Color(0xFFFFF200),  // Yellow
    'O2': Color(0xFFF06EA9),  // Pink
    'E': Color(0xFFF26522),   // Orange
    'N': Color(0xFF8DC63F),   // Light Green
    'T': Color(0xFF6DCFF6),   // Light Blue
    'RB': Color(0xFFED1C24),  // Red
    'N1': Color(0xFF006837),  // Dark Green
    'C2': Color(0xFFF26522),  // Orange
    'TR': Color(0xFF00A99D),  // Teal
    'QM': Color(0xFFFBC99A),  // Peach
  };

  static Color getColor(String? lineId) {
    if (lineId == null) return Colors.grey;
    
    // Clean line ID (in case of spaces or extra chars)
    final cleanId = lineId.trim().toUpperCase();
    
    // Direct match
    if (_lineColors.containsKey(cleanId)) {
      return _lineColors[cleanId]!;
    }
    
    // Fallback if not found
    return Colors.grey;
  }
}
