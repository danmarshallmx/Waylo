import 'package:flutter/material.dart';

/// Official Waylo Brand Logo Widget
/// Renders the signature purple squircle emblem with stylized 'W' and optional typography.
class WayloLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const WayloLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/logo/waylo_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF7C3AED),
            child: Icon(
              Icons.travel_explore_rounded,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );

    if (!showText) {
      return logoIcon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WAYLO',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.52,
                    letterSpacing: 1.2,
                    color: textColor ??
                        (isDark
                            ? Colors.white
                            : const Color(0xFF1E1238)),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Offline Smart Travel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: size * 0.26,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
