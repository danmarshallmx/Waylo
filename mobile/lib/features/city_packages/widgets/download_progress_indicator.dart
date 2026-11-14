import 'dart:math';

import 'package:flutter/material.dart';

class DownloadProgressIndicator extends StatelessWidget {
  final double progress;
  final VoidCallback? onCancel;
  final double size;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    this.onCancel,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.0,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          // Percentage text and cancel button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: Icon(
                    Icons.close,
                    size: max(12, size * 0.22),
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
