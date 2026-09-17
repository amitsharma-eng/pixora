import 'package:flutter/material.dart';

/// A widget that displays a placeholder state while an image is loading.
class PixoraPlaceholder extends StatefulWidget {
  /// Creates a [PixoraPlaceholder].
  const PixoraPlaceholder({super.key, this.borderRadius});

  /// The border radius to apply to the placeholder.
  final BorderRadius? borderRadius;

  /// Creates a shimmer-style placeholder.
  factory PixoraPlaceholder.shimmer({Key? key, BorderRadius? borderRadius}) =>
      PixoraPlaceholder(key: key, borderRadius: borderRadius);

  @override
  State<PixoraPlaceholder> createState() => _PixoraPlaceholderState();
}

class _PixoraPlaceholderState extends State<PixoraPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final value = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + value * 2, 0),
              end: Alignment(value * 2, 0),
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
