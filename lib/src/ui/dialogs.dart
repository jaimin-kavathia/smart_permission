import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'permission_dialog_style.dart';
import '../core/config.dart';

/// Custom dialog builder signature.
///
/// Provide your own implementation and set it via:
/// ```dart
/// SmartPermission.config.customDialogBuilder = myBuilder;
/// ```
typedef PermissionDialogBuilder = Future<bool?> Function(
  BuildContext context, {
  required PermissionDialogStyle style,
  required String title,
  required String message,
  required String primaryText,
  required String secondaryText,
});

/// Default dialog implementation for Material/Cupertino/adaptive styles.
Future<bool?> showPermissionDialog(
  BuildContext context, {
  required PermissionDialogStyle style,
  required String title,
  required String message,
  required String primaryText,
  required String secondaryText,
}) {
  switch (style) {
    case PermissionDialogStyle.material:
      final cfg = SmartPermissionConfig.instance;
      final effectiveBrightness =
          cfg.brightness ?? Theme.of(context).brightness;
      final seed = cfg.primaryColor ?? Colors.indigo;
      final colorScheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: effectiveBrightness,
      );
      final theme = ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        brightness: effectiveBrightness,
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            backgroundColor: colorScheme.primary,
            shape: const StadiumBorder(),
          ),
        ),
      );
      return showDialog<bool>(
        context: context,
        builder: (ctx) => Theme(
          data: theme,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(secondaryText),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(primaryText),
              ),
            ],
          ),
        ),
      );
    case PermissionDialogStyle.cupertino:
      final cfg = SmartPermissionConfig.instance;
      final isDark = cfg.brightness == Brightness.dark;
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            platformBrightness:
                cfg.brightness ?? MediaQuery.of(ctx).platformBrightness,
          ),
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: cfg.brightness,
              primaryColor: cfg.primaryColor ??
                  (isDark
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.activeBlue),
            ),
            child: CupertinoAlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: false,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(secondaryText),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(primaryText),
                ),
              ],
            ),
          ),
        ),
      );
    case PermissionDialogStyle.adaptive:
      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        return showPermissionDialog(
          context,
          style: PermissionDialogStyle.cupertino,
          title: title,
          message: message,
          primaryText: primaryText,
          secondaryText: secondaryText,
        );
      } else {
        return showPermissionDialog(
          context,
          style: PermissionDialogStyle.material,
          title: title,
          message: message,
          primaryText: primaryText,
          secondaryText: secondaryText,
        );
      }
  }
}
