import 'package:flutter/material.dart';
import 'package:smart_permission/smart_permission.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _isDark = false;
  Color _primary = Colors.indigo;
  PermissionDialogStyle _style = PermissionDialogStyle.adaptive;
  bool _useCustomText = false;
  bool _useCustomDialog = false;

  @override
  void initState() {
    super.initState();
    SmartPermission.config
      ..brightness = Brightness.light
      ..primaryColor = _primary
      ..analytics = InMemoryPermissionAnalyticsTracker();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
      SmartPermission.config.brightness = _isDark
          ? Brightness.dark
          : Brightness.light;
    });
  }

  void _cyclePrimary() {
    setState(() {
      if (_primary == Colors.indigo) {
        _primary = Colors.teal;
      } else if (_primary == Colors.teal) {
        _primary = Colors.deepOrange;
      } else {
        _primary = Colors.indigo;
      }
      SmartPermission.config.primaryColor = _primary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: _isDark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'smart_permission example',
      theme: theme,
      home: ExampleHomePage(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
        onCyclePrimary: _cyclePrimary,
        style: _style,
        onStyleChanged: (s) => setState(() => _style = s),
        useCustomText: _useCustomText,
        onToggleCustomText: () {
          setState(() {
            _useCustomText = !_useCustomText;
            if (_useCustomText) {
              SmartPermission.config
                ..titleProvider = (p) {
                  if (p == Permission.camera) return 'Camera Access Needed';
                  if (p == Permission.microphone) {
                    return 'Microphone Access Needed';
                  }
                  if (p == Permission.locationWhenInUse) {
                    return 'Location Access Needed';
                  }
                  return null;
                }
                ..descriptionProvider = (p) {
                  if (p == Permission.camera) {
                    return 'We need the camera to scan QR codes.';
                  }
                  if (p == Permission.microphone) {
                    return 'We need the microphone for voice features.';
                  }
                  if (p == Permission.locationWhenInUse) {
                    return 'We use your location to show nearby stores.';
                  }
                  return null;
                };
            } else {
              SmartPermission.config
                ..titleProvider = null
                ..descriptionProvider = null;
            }
          });
        },
        useCustomDialog: _useCustomDialog,
        onToggleCustomDialog: () {
          setState(() {
            _useCustomDialog = !_useCustomDialog;
            if (_useCustomDialog) {
              SmartPermission.config.customDialogBuilder =
                  _demoCustomDialogBuilder;
            } else {
              SmartPermission.config.customDialogBuilder = null;
            }
          });
        },
      ),
    );
  }

  Future<bool?> _demoCustomDialogBuilder(
    BuildContext context, {
    required PermissionDialogStyle style,
    required String title,
    required String message,
    required String primaryText,
    required String secondaryText,
  }) async {
    // Example: a bottom sheet with custom layout
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(
                        ctx,
                      ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(
                  ctx,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(secondaryText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(primaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onCyclePrimary,
    required this.style,
    required this.onStyleChanged,
    required this.useCustomText,
    required this.onToggleCustomText,
    required this.useCustomDialog,
    required this.onToggleCustomDialog,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onCyclePrimary;
  final PermissionDialogStyle style;
  final ValueChanged<PermissionDialogStyle> onStyleChanged;
  final bool useCustomText;
  final VoidCallback onToggleCustomText;
  final bool useCustomDialog;
  final VoidCallback onToggleCustomDialog;

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final Map<Permission, bool> _grants = <Permission, bool>{};

  Future<void> _request(Permission p, {String? description}) async {
    final ok = await SmartPermission.request(
      context,
      permission: p,
      style: widget.style,
      description: description,
    );
    if (!mounted) return;
    setState(() => _grants[p] = ok);
  }

  Future<void> _requestBatch() async {
    final result = await SmartPermission.requestMultiple(
      context,
      permissions: [Permission.camera, Permission.microphone],
      style: widget.style,
    );
    if (!mounted) return;
    setState(() => _grants.addAll(result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('smart_permission example'),
        actions: [
          IconButton(
            tooltip: 'Toggle ${widget.isDark ? 'Light' : 'Dark'} Theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Change Primary Color',
            onPressed: widget.onCyclePrimary,
            icon: const Icon(Icons.palette_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Dialog Style:'),
              const SizedBox(width: 12),
              DropdownButton<PermissionDialogStyle>(
                value: widget.style,
                onChanged: (v) => v != null ? widget.onStyleChanged(v) : null,
                items: const [
                  DropdownMenuItem(
                    value: PermissionDialogStyle.adaptive,
                    child: Text('Adaptive'),
                  ),
                  DropdownMenuItem(
                    value: PermissionDialogStyle.material,
                    child: Text('Material'),
                  ),
                  DropdownMenuItem(
                    value: PermissionDialogStyle.cupertino,
                    child: Text('Cupertino'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Use custom per-permission titles/descriptions'),
            value: widget.useCustomText,
            onChanged: (_) => widget.onToggleCustomText(),
          ),
          SwitchListTile(
            title: const Text('Use custom dialog builder (bottom sheet demo)'),
            value: widget.useCustomDialog,
            onChanged: (_) => widget.onToggleCustomDialog(),
          ),
          _AnalyticsPanel(),
          const SizedBox(height: 16),
          Text(
            'Single permissions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.camera,
                  description: 'We need camera to scan QR codes.',
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text('Camera • ${_label(Permission.camera)}'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.microphone,
                  description: 'We need mic for voice features.',
                ),
                icon: const Icon(Icons.mic_none_outlined),
                label: Text('Microphone • ${_label(Permission.microphone)}'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.locationWhenInUse,
                  description: 'We need location to show nearby stores.',
                ),
                icon: const Icon(Icons.my_location_outlined),
                label: Text(
                  'Location • ${_label(Permission.locationWhenInUse)}',
                ),
              ),
              // Explicit Web/Windows-friendly location button using generic location
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.location,
                  description:
                      'Please allow location in browser/system settings if prompted.',
                ),
                icon: const Icon(Icons.location_on_outlined),
                label: Text(
                  'Location (web/windows) • ${_label(Permission.location)}',
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.photos,
                  description: 'We need photos access to pick images.',
                ),
                icon: const Icon(Icons.photo_outlined),
                label: Text('Photos • ${_label(Permission.photos)}'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _request(
                  Permission.notification,
                  description: 'We send updates about important activity.',
                ),
                icon: const Icon(Icons.notifications_none_outlined),
                label: Text(
                  'Notifications • ${_label(Permission.notification)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Batch', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _requestBatch,
            icon: const Icon(Icons.select_all_outlined),
            label: const Text('Request Camera + Microphone'),
          ),
          const SizedBox(height: 24),
          Text('Results', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._grants.entries.map(
            (e) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(e.key.toString()),
              trailing: Text(e.value ? 'granted' : 'denied'),
            ),
          ),
        ],
      ),
    );
  }

  String _label(Permission p) {
    final v = _grants[p];
    if (v == null) return 'unknown';
    return v ? 'granted' : 'denied';
  }
}

class _AnalyticsPanel extends StatefulWidget {
  @override
  State<_AnalyticsPanel> createState() => _AnalyticsPanelState();
}

/// Extend [PermissionAnalyticsTracker] (rather than implementing it) so new
/// hooks added in future versions don't break your tracker.
class _PanelAnalyticsTracker extends PermissionAnalyticsTracker {
  _PanelAnalyticsTracker({
    required this.onDeniedEvent,
    required this.onPermaEvent,
  });

  final void Function(Permission) onDeniedEvent;
  final void Function(Permission) onPermaEvent;

  @override
  void onDenied(Permission permission) => onDeniedEvent(permission);

  @override
  void onPermanentlyDenied(Permission permission) => onPermaEvent(permission);
}

class _AnalyticsPanelState extends State<_AnalyticsPanel> {
  final Map<Permission, int> _denied = <Permission, int>{};
  final Map<Permission, int> _perma = <Permission, int>{};

  @override
  void initState() {
    super.initState();
    SmartPermission.config.analytics = _PanelAnalyticsTracker(
      onDeniedEvent: (p) =>
          setState(() => _denied.update(p, (v) => v + 1, ifAbsent: () => 1)),
      onPermaEvent: (p) =>
          setState(() => _perma.update(p, (v) => v + 1, ifAbsent: () => 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Analytics (demo tracker)'),
      subtitle: const Text(
        'Counts of denied/permanently denied during this session',
      ),
      children: [
        if (_denied.isEmpty && _perma.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No events yet.'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Denied: ${_denied.map((k, v) => MapEntry(k.toString(), v))}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Permanently denied: ${_perma.map((k, v) => MapEntry(k.toString(), v))}',
            ),
          ),
        ],
      ],
    );
  }
}
