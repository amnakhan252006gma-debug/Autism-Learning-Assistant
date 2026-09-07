import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BigNavCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const BigNavCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<BigNavCard> createState() => _BigNavCardState();
}

class _BigNavCardState extends State<BigNavCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
          scale: _pressed ? .95 : 1,
          duration: AppTheme.animationFast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppTheme.animationNormal,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: .20),
                  blurRadius: _pressed ? 10 : 20,
                  offset: Offset(0, _pressed ? 4 : 9),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _pressed ? .9 : 1,
                    duration: AppTheme.animationFast,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .22),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: AppTheme.iconLG,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(10),
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
