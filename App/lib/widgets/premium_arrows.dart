import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Premium arrow widget with thin stroke and optional animation
class PremiumArrow extends StatefulWidget {
  final ArrowDirection direction;
  final double size;
  final Color? color;
  final bool animated;
  final bool isActive;

  const PremiumArrow({
    super.key,
    required this.direction,
    this.size = 18,
    this.color,
    this.animated = false,
    this.isActive = false,
  });

  @override
  State<PremiumArrow> createState() => _PremiumArrowState();
}

class _PremiumArrowState extends State<PremiumArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _offsetAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PremiumArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && widget.isActive) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  IconData _getIcon() {
    switch (widget.direction) {
      case ArrowDirection.right:
        return LucideIcons.arrowRight;
      case ArrowDirection.left:
        return LucideIcons.arrowLeft;
      case ArrowDirection.up:
        return LucideIcons.arrowUp;
      case ArrowDirection.down:
        return LucideIcons.arrowDown;
      case ArrowDirection.chevronRight:
        return LucideIcons.chevronRight;
      case ArrowDirection.chevronDown:
        return LucideIcons.chevronDown;
    }
  }

  Offset _getOffset() {
    switch (widget.direction) {
      case ArrowDirection.right:
      case ArrowDirection.chevronRight:
        return Offset(_offsetAnimation.value, 0);
      case ArrowDirection.left:
        return Offset(-_offsetAnimation.value, 0);
      case ArrowDirection.up:
        return Offset(0, -_offsetAnimation.value);
      case ArrowDirection.down:
      case ArrowDirection.chevronDown:
        return Offset(0, _offsetAnimation.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    Widget arrow = Icon(
      _getIcon(),
      size: widget.size,
      color: color,
    );

    if (widget.animated) {
      arrow = AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _getOffset(),
            child: child,
          );
        },
        child: arrow,
      );
    }

    return arrow;
  }
}

enum ArrowDirection {
  right,
  left,
  up,
  down,
  chevronRight,
  chevronDown,
}

/// Vertical connector with premium arrow between stops
class VerticalStopConnector extends StatelessWidget {
  final Color color;
  final double height;

  const VerticalStopConnector({
    super.key,
    required this.color,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.chevronDown,
      size: 16,
      color: color.withValues(alpha: 0.6),
    );
  }
}

/// Direction chip with premium arrow and hover animation
class DirectionChip extends StatefulWidget {
  final bool isSelected;
  final bool isOutbound; // true = Ida, false = Vuelta
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const DirectionChip({
    super.key,
    required this.isSelected,
    required this.isOutbound,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<DirectionChip> createState() => _DirectionChipState();
}

class _DirectionChipState extends State<DirectionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final arrowDirection = widget.isOutbound ? ArrowDirection.right : ArrowDirection.left;
    final iconColor = widget.isSelected ? Colors.white : Colors.grey.shade600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? widget.activeColor : Colors.grey.shade400,
              width: 1.5,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PremiumArrow(
                direction: arrowDirection,
                size: 16,
                color: iconColor,
                animated: true,
                isActive: _isHovered || widget.isSelected,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: widget.isSelected ? Colors.white : Colors.grey.shade700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
