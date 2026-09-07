import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large accessible button with a subtle press animation.
class ChildButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final double? width;

  const ChildButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.width,
  });

  @override
  State<ChildButton> createState() => _ChildButtonState();
}

class _ChildButtonState extends State<ChildButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.color ?? AppTheme.primary;
    final bool isLight =
        ThemeData.estimateBrightnessForColor(btnColor) == Brightness.light;
    final Color foreground = isLight ? AppTheme.textPrimary : Colors.white;

    return Semantics(
      excludeSemantics: true,
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? .97 : 1,
          duration: AppTheme.animationFast,
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: isLight ? Border.all(color: AppTheme.outline) : null,
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? AppTheme.cardShadow
                        : btnColor.withValues(alpha: .18),
                    blurRadius: _pressed ? 8 : 16,
                    offset: Offset(0, _pressed ? 3 : 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: AppTheme.iconSM, color: foreground),
                    const SizedBox(width: AppTheme.spaceXS),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
