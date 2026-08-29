import 'package:flutter/material.dart';

import 'app_states.dart';

/// Backward-compatible aliases so existing screens keep working while the
/// brand-styled [AppState] components remain the single source of truth.
///
/// Prefer the components in `app_states.dart` directly for new code.

/// Centered loading indicator used by async screens.
class AsyncLoadingView extends StatelessWidget {
  const AsyncLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Empty-state view (brand-styled).
class AsyncEmptyView extends StatelessWidget {
  const AsyncEmptyView({
    super.key,
    this.message = 'Tidak ada data',
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: message,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Error-state view with a retry button (brand-styled).
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(message: message, onRetry: onRetry);
  }
}
