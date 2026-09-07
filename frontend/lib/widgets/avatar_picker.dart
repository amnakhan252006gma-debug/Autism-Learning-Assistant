import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarPicker extends StatefulWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  const AvatarPicker({
    super.key,
    required this.emoji,
    required this.onTap,
    this.selected = false,
    this.size = 72,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .9 : (widget.selected ? 1.06 : 1),
        duration: AppTheme.animationFast,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: AppTheme.animationNormal,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selected ? AppTheme.primary : AppTheme.surface,
            border: Border.all(
              color: widget.selected ? AppTheme.primary : AppTheme.outline,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.selected
                    ? AppTheme.primary.withValues(alpha: .20)
                    : AppTheme.cardShadow,
                blurRadius: widget.selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * .5),
          ),
        ),
      ),
    );
  }
}
