import 'package:flutter/widgets.dart';

/// Represents the various states of an image loading process in Pixora.
sealed class PixoraImageState {
  /// Const constructor for sub-classes.
  const PixoraImageState();
}

/// State when the image is currently being loaded.
class PixoraLoading extends PixoraImageState {
  /// Creates a [PixoraLoading] state.
  const PixoraLoading();
}

/// State when the image has been successfully loaded.
class PixoraSuccess extends PixoraImageState {
  /// Creates a [PixoraSuccess] state with the loaded [image].
  const PixoraSuccess(this.image);

  /// The loaded image provider.
  final ImageProvider image;
}

/// State when the image loading has failed.
class PixoraFailure extends PixoraImageState {
  /// Creates a [PixoraFailure] state with the [error] and optional [stackTrace].
  const PixoraFailure(this.error, [this.stackTrace]);

  /// The error that occurred.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;
}
