import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Consistent loading / error / empty state widgets, used everywhere a
/// screen depends on async data (providers, network, location, etc).
/// Errors are shown as human-readable copy; the raw technical message is
/// still logged via debugPrint by the caller if needed.

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(message, style: AppTextStyles.bodySecondary)),
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.error.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodySecondary),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodySecondary),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Maps a thrown error to human-readable copy for the UI, while the
/// original technical detail stays available via [technical] for logging.
class FriendlyError {
  const FriendlyError(this.message, this.technical);

  final String message;
  final String technical;

  factory FriendlyError.from(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');

    if (raw.toLowerCase().contains('session expired') ||
        raw.toLowerCase().contains('401')) {
      return FriendlyError(
        'Your session has expired. Sign in again to continue.',
        raw,
      );
    }
    if (raw.toLowerCase().contains('timeout') ||
        raw.toLowerCase().contains('took too long')) {
      return FriendlyError(
        'The server is taking too long to respond. Check your connection and try again.',
        raw,
      );
    }
    if (raw.toLowerCase().contains('unable to connect') ||
        raw.toLowerCase().contains('socketexception')) {
      return FriendlyError('Unable to reach FuelSense servers right now.', raw);
    }
    if (raw.toLowerCase().contains('location')) {
      return FriendlyError(raw, raw);
    }
    return FriendlyError(raw, raw);
  }
}
