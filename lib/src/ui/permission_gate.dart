import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' show Permission;

import '../core/config.dart';
import '../core/smart_permission_result.dart';
import '../smart_permission_public.dart';
import 'permission_dialog_style.dart';

/// Builds what [PermissionGate] shows while [permission] cannot be used.
///
/// [result] says why (denied, permanentlyDenied, restricted, error) and
/// [request] runs the appropriate action: the full request flow, or opening
/// app settings when the permission is permanently denied.
typedef PermissionGateFallbackBuilder = Widget Function(
  BuildContext context,
  SmartPermissionResult result,
  VoidCallback request,
);

/// Shows [builder] only while [permission] is usable (granted, limited, or
/// provisional), and a fallback with a call to action otherwise.
///
/// The gate re-checks the permission whenever the app returns to the
/// foreground, so changes made in the system settings show up immediately.
///
/// ```dart
/// PermissionGate(
///   permission: Permission.camera,
///   description: 'We need the camera to scan QR codes.',
///   builder: (context) => const QrScanner(),
/// )
/// ```
class PermissionGate extends StatefulWidget {
  /// Creates a gate for [permission].
  const PermissionGate({
    super.key,
    required this.permission,
    required this.builder,
    this.fallbackBuilder,
    this.loadingBuilder,
    this.requestOnMount = false,
    this.onChanged,
    this.style,
    this.title,
    this.description,
    this.showRationaleFirst,
  });

  /// The permission guarding [builder].
  final Permission permission;

  /// Builds the protected content once [permission] is usable.
  final WidgetBuilder builder;

  /// Builds the content shown while [permission] is not usable. Defaults to
  /// a centered title, description, and a button ("Allow", or "Open
  /// Settings" when permanently denied).
  final PermissionGateFallbackBuilder? fallbackBuilder;

  /// Builds the content shown while the first status check is running.
  /// Defaults to an empty box.
  final WidgetBuilder? loadingBuilder;

  /// When true, the request flow starts as soon as the gate is shown
  /// (instead of waiting for the user to tap the fallback button).
  final bool requestOnMount;

  /// Called whenever the known result changes.
  final ValueChanged<SmartPermissionResult>? onChanged;

  /// Dialog style for the request flow and the default fallback button.
  /// Defaults to [SmartPermissionConfig.defaultDialogStyle].
  final PermissionDialogStyle? style;

  /// Title for the default fallback and the request flow's dialogs.
  final String? title;

  /// Description for the default fallback and the request flow's dialogs.
  final String? description;

  /// Passed to the request flow; see `SmartPermission.requestResult`.
  final bool? showRationaleFirst;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  SmartPermissionResult? _result;
  bool _busy = false;

  // Incremented by every check/request so a slow, stale one can't overwrite
  // a newer result.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(PermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permission != widget.permission) {
      _result = null;
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Native prompts also pause/resume the app; the request flow reports
    // its own result, so only refresh when idle.
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  Future<void> _start() async {
    await _refresh();
    if (widget.requestOnMount &&
        mounted &&
        _result != null &&
        !_result!.canProceed) {
      await _request();
    }
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    final result = await SmartPermission.status(widget.permission);
    if (!mounted || generation != _generation) return;
    _update(result);
  }

  Future<void> _request() async {
    if (_busy) return;
    _busy = true;
    final generation = ++_generation;
    try {
      if (_result == SmartPermissionResult.permanentlyDenied) {
        // Only settings can help; the resume observer re-checks on return.
        await SmartPermission.openSettings();
        return;
      }
      final result = await SmartPermission.requestResult(
        permission: widget.permission,
        context: context,
        style: widget.style,
        title: widget.title,
        description: widget.description,
        showRationaleFirst: widget.showRationaleFirst,
      );
      if (!mounted || generation != _generation) return;
      _update(result);
    } finally {
      _busy = false;
    }
  }

  void _update(SmartPermissionResult result) {
    if (result == _result) return;
    setState(() => _result = result);
    widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }
    if (result.canProceed) return widget.builder(context);
    final fallback = widget.fallbackBuilder;
    if (fallback != null) return fallback(context, result, _request);
    return _DefaultGateFallback(
      permission: widget.permission,
      result: result,
      onRequest: _request,
      style: widget.style,
      title: widget.title,
      description: widget.description,
    );
  }
}

class _DefaultGateFallback extends StatelessWidget {
  const _DefaultGateFallback({
    required this.permission,
    required this.result,
    required this.onRequest,
    this.style,
    this.title,
    this.description,
  });

  final Permission permission;
  final SmartPermissionResult result;
  final VoidCallback onRequest;
  final PermissionDialogStyle? style;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final cfg = SmartPermissionConfig.instance;
    final strings = cfg.strings;
    final restricted = result == SmartPermissionResult.restricted;
    final blocked = result == SmartPermissionResult.permanentlyDenied;

    final heading = cfg.resolveTitle(permission, title) ??
        (restricted
            ? strings.permissionRestrictedTitle
            : strings.permissionRequiredTitle);
    final explanation = cfg.resolveDescription(permission, description) ?? '';
    final body = restricted
        ? strings.restrictedMessage
        : blocked
            ? '$explanation ${strings.blockedMessage}'.trim()
            : explanation;
    final label = blocked ? strings.openSettings : strings.allow;

    final effectiveStyle = style ?? cfg.defaultDialogStyle;
    final platform = Theme.of(context).platform;
    final cupertino = effectiveStyle == PermissionDialogStyle.cupertino ||
        (effectiveStyle == PermissionDialogStyle.adaptive &&
            (platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS));
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(heading,
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body,
                  style: textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (!restricted) ...[
              const SizedBox(height: 16),
              cupertino
                  ? CupertinoButton.filled(
                      onPressed: onRequest,
                      child: Text(label),
                    )
                  : FilledButton(onPressed: onRequest, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
