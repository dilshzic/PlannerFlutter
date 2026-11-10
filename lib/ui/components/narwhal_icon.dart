import 'package:flutter/material.dart';

/// A custom widget that displays the Narwhal mascot/AI icon across the application.
class NarwhalIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;
  final bool isSelected;

  const NarwhalIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.opacity = 1.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? Colors.white : const Color(0xFF1E293B));

    Widget image = Image.asset(
      'assets/icons/narwhal_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: effectiveColor,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.auto_awesome,
        size: size,
        color: effectiveColor,
      ),
    );

    if (opacity < 1.0 && !isSelected) {
      image = Opacity(opacity: opacity, child: image);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: image),
    );
  }
}
