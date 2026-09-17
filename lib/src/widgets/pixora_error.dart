import 'package:flutter/material.dart';

/// A widget that displays an error state for Pixora images.
class PixoraErrorWidget extends StatelessWidget {
  /// Creates a [PixoraErrorWidget].
  const PixoraErrorWidget({
    super.key,
    this.onRetry,
    this.icon = Icons.broken_image_outlined,
    this.message = 'Unable to load image',
  });

  /// Optional callback to retry loading the image.
  final VoidCallback? onRetry;

  /// The icon to display in the error state.
  final IconData icon;

  /// The error message to display.
  final String message;

  /// Creates a [PixoraErrorWidget] optimized for retry scenarios.
  factory PixoraErrorWidget.retry({
    Key? key,
    VoidCallback? onRetry,
    String message = 'Unable to load image',
  }) => PixoraErrorWidget(key: key, onRetry: onRetry, message: message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 4),
                const Text('Retry'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
