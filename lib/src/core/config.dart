import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/dialogs.dart';
import '../ui/permission_dialog_style.dart';
import 'permission_gateway.dart';
import 'strings.dart';

typedef DescriptionProvider = String? Function(Permission permission);
typedef TitleProvider = String? Function(Permission permission);

/// Hook interface to observe user decisions.
///
/// Implement this to pipe analytics (e.g., to Firebase or Segment):
/// ```dart
/// SmartPermission.config.analytics = MyAnalytics();
/// ```
/// Prefer `extends` over `implements` so that future hook additions do not
/// break your implementation.
abstract class PermissionAnalyticsTracker {
  /// Called when a request flow starts for a permission that is not yet
  /// granted (before any native prompt or dialog).
  void onRequested(Permission permission) {}

  /// Called when a request flow ends with the permission usable
  /// (granted, limited, or provisional).
  void onGranted(Permission permission) {}

  /// Called after the user denies a permission from the dialog flow.
  void onDenied(Permission permission) {}

  /// Called after the user refuses Settings or returns still blocked.
  void onPermanentlyDenied(Permission permission) {}

  /// Called when the OS reports the permission as restricted
  /// (e.g. parental controls).
  void onRestricted(Permission permission) {}
}

class InMemoryPermissionAnalyticsTracker extends PermissionAnalyticsTracker {
  final Map<Permission, int> requestedCounts = <Permission, int>{};
  final Map<Permission, int> grantedCounts = <Permission, int>{};
  final Map<Permission, int> deniedCounts = <Permission, int>{};
  final Map<Permission, int> permanentlyDeniedCounts = <Permission, int>{};
  final Map<Permission, int> restrictedCounts = <Permission, int>{};

  @override
  void onRequested(Permission permission) {
    requestedCounts.update(permission, (v) => v + 1, ifAbsent: () => 1);
  }

  @override
  void onGranted(Permission permission) {
    grantedCounts.update(permission, (v) => v + 1, ifAbsent: () => 1);
  }

  @override
  void onDenied(Permission permission) {
    deniedCounts.update(permission, (v) => v + 1, ifAbsent: () => 1);
  }

  @override
  void onPermanentlyDenied(Permission permission) {
    permanentlyDeniedCounts.update(permission, (v) => v + 1, ifAbsent: () => 1);
  }

  @override
  void onRestricted(Permission permission) {
    restrictedCounts.update(permission, (v) => v + 1, ifAbsent: () => 1);
  }
}

/// Global configuration for SmartPermission.
///
/// Typical setup:
/// ```dart
/// SmartPermission.config
///   ..brightness = Brightness.light
///   ..primaryColor = Colors.indigo
///   ..titleProvider = (p) => p == Permission.camera ? 'Camera Access' : null
///   ..descriptionProvider = (p) => p == Permission.camera
///       ? 'We need camera to scan QR codes.'
///       : null;
/// ```
class SmartPermissionConfig {
  SmartPermissionConfig._internal();
  static final SmartPermissionConfig instance =
      SmartPermissionConfig._internal();

  /// When set, dialogs can be shown without passing a [BuildContext]
  /// (used by `SmartPermission.requestResult` and friends when `context`
  /// is omitted). Assign the same key you pass to your `MaterialApp`.
  GlobalKey<NavigatorState>? navigatorKey;

  PermissionDialogBuilder? customDialogBuilder;

  /// Style used when a call does not specify one.
  PermissionDialogStyle defaultDialogStyle = PermissionDialogStyle.adaptive;

  PermissionAnalyticsTracker analytics = InMemoryPermissionAnalyticsTracker();

  /// All user-facing dialog strings; replace to localize.
  SmartPermissionStrings strings = const SmartPermissionStrings();

  /// When true, an explanation dialog is shown *before* the first native
  /// prompt (recommended: you only get one native ask on iOS).
  /// Can be overridden per call via `showRationaleFirst`.
  bool showRationaleBeforeRequest = false;

  /// Observes internal errors (platform call failures, dialog failures).
  /// Errors are always logged with `debugPrint`; this lets you also report
  /// them to e.g. Crashlytics.
  void Function(Object error, StackTrace stackTrace)? onError;

  /// Platform access used by the flows. Replace with a fake in tests.
  SmartPermissionGateway gateway = const DefaultSmartPermissionGateway();

  /// Restores every setting to its default value. Handy in tests.
  void resetToDefaults() {
    navigatorKey = null;
    customDialogBuilder = null;
    defaultDialogStyle = PermissionDialogStyle.adaptive;
    analytics = InMemoryPermissionAnalyticsTracker();
    strings = const SmartPermissionStrings();
    showRationaleBeforeRequest = false;
    onError = null;
    gateway = const DefaultSmartPermissionGateway();
    brightness = null;
    primaryColor = null;
    descriptionProvider = null;
    titleProvider = null;
  }

  // Theming
  Brightness? brightness; // light/dark
  Color? primaryColor; // seed/primary color

  // Platform-aware description provider
  DescriptionProvider? descriptionProvider;
  // Platform-aware title provider
  TitleProvider? titleProvider;

  // Built-in defaults for titles and descriptions per permission.
  final Map<Permission, String> _defaultTitles = <Permission, String>{
    Permission.calendarWriteOnly: 'Calendar Write Access',
    Permission.calendarFullAccess: 'Calendar Full Access',
    Permission.camera: 'Camera Access',
    Permission.contacts: 'Contacts Access',
    Permission.location: 'Location Access',
    Permission.locationAlways: 'Background Location Access',
    Permission.locationWhenInUse: 'Location Access (While Using)',
    Permission.mediaLibrary: 'Media Library Access',
    Permission.microphone: 'Microphone Access',
    Permission.phone: 'Phone Access',
    Permission.photos: 'Photos Access',
    Permission.photosAddOnly: 'Add-Only Photos Access',
    Permission.reminders: 'Reminders Access',
    Permission.sensors: 'Sensors Access',
    Permission.sms: 'SMS Access',
    Permission.speech: 'Speech Recognition',
    Permission.storage: 'Storage Access',
    Permission.ignoreBatteryOptimizations: 'Ignore Battery Optimizations',
    Permission.notification: 'Notifications',
    Permission.accessMediaLocation: 'Access Media Location',
    Permission.activityRecognition: 'Activity Recognition',
    Permission.bluetooth: 'Bluetooth',
    Permission.manageExternalStorage: 'Manage External Storage',
    Permission.systemAlertWindow: 'Display Over Other Apps',
    Permission.requestInstallPackages: 'Install Unknown Apps',
    Permission.appTrackingTransparency: 'App Tracking Transparency',
    Permission.criticalAlerts: 'Critical Alerts',
    Permission.accessNotificationPolicy: 'Do Not Disturb Access',
    Permission.bluetoothScan: 'Bluetooth Scan',
    Permission.bluetoothAdvertise: 'Bluetooth Advertise',
    Permission.bluetoothConnect: 'Bluetooth Connect',
    Permission.nearbyWifiDevices: 'Nearby Wi‑Fi Devices',
    Permission.videos: 'Videos Access',
    Permission.audio: 'Audio Access',
    Permission.scheduleExactAlarm: 'Schedule Exact Alarms',
    Permission.sensorsAlways: 'Sensors (Always)',
    Permission.assistant: 'Assistant Access',
    Permission.backgroundRefresh: 'Background App Refresh',
    Permission.accessLocalNetwork: 'Local Network Access',
    Permission.unknown: 'Permission Required',
  };

  final Map<Permission, String> _defaultDescriptions = <Permission, String>{
    Permission.calendarWriteOnly: 'Allow writing new events to your calendar.',
    Permission.calendarFullAccess:
        'Allow full read/write access to your calendars.',
    Permission.camera: 'We need camera access to capture photos or scan codes.',
    Permission.contacts: 'Allow access to your contacts to pick or share.',
    Permission.location:
        'We need your location to show nearby content and services.',
    Permission.locationAlways:
        'Allow background location for accurate updates.',
    Permission.locationWhenInUse: 'Allow location while using the app.',
    Permission.mediaLibrary:
        'Allow access to your media library to select content.',
    Permission.microphone:
        'Allow microphone access for voice or audio capture.',
    Permission.phone: 'Allow phone access for calls and phone state.',
    Permission.photos: 'Allow access to your photos to select and upload.',
    Permission.photosAddOnly:
        'Allow adding new photos without full library access.',
    Permission.reminders: 'Allow access to create and manage reminders.',
    Permission.sensors: 'Allow access to device sensors for enhanced features.',
    Permission.sms: 'Allow SMS access for reading or sending messages.',
    Permission.speech: 'Allow speech recognition to transcribe voice.',
    Permission.storage: 'Allow storage access to read or save files.',
    Permission.ignoreBatteryOptimizations:
        'Exclude the app from battery optimizations.',
    Permission.notification: 'Allow notifications to keep you informed.',
    Permission.accessMediaLocation: 'Allow access to media location metadata.',
    Permission.activityRecognition:
        'Allow activity recognition for fitness and motion.',
    Permission.bluetooth: 'Allow Bluetooth to connect to nearby devices.',
    Permission.manageExternalStorage:
        'Allow managing files across external storage.',
    Permission.systemAlertWindow: 'Allow showing overlays above other apps.',
    Permission.requestInstallPackages:
        'Allow installation of apps from this source.',
    Permission.appTrackingTransparency:
        'Allow tracking across apps and websites.',
    Permission.criticalAlerts:
        'Allow critical alerts to break through focus modes.',
    Permission.accessNotificationPolicy:
        'Allow control of Do Not Disturb settings.',
    Permission.bluetoothScan: 'Allow scanning for nearby Bluetooth devices.',
    Permission.bluetoothAdvertise:
        'Allow advertising this device over Bluetooth.',
    Permission.bluetoothConnect:
        'Allow connecting to paired Bluetooth devices.',
    Permission.nearbyWifiDevices: 'Allow discovery of nearby Wi‑Fi devices.',
    Permission.videos: 'Allow access to your videos to select and upload.',
    Permission.audio: 'Allow access to your audio files.',
    Permission.scheduleExactAlarm: 'Allow the app to schedule exact alarms.',
    Permission.sensorsAlways:
        'Allow continuous sensor access in the background.',
    Permission.assistant: 'Allow assistant integrations to function properly.',
    Permission.backgroundRefresh:
        'Allow the app to refresh content in background.',
    Permission.accessLocalNetwork:
        'Allow discovery and connection to devices on your local network.',
    Permission.unknown: 'This permission is required for full functionality.',
  };

  String? resolveDescription(
      Permission permission, String? explicitDescription) {
    if (explicitDescription != null && explicitDescription.isNotEmpty) {
      return explicitDescription;
    }
    final provider = descriptionProvider;
    if (provider != null) return provider(permission);
    // Built-in default
    final builtIn = _defaultDescriptions[permission];
    if (builtIn != null) return builtIn;
    // Fallback generic (localizable via [strings])
    return strings.formatGenericRationale('$permission');
  }

  String? resolveTitle(Permission permission, String? explicitTitle) {
    if (explicitTitle != null && explicitTitle.isNotEmpty) return explicitTitle;
    final provider = titleProvider;
    if (provider != null) return provider(permission);
    // Built-in default
    final builtIn = _defaultTitles[permission];
    if (builtIn != null) return builtIn;
    return 'Permission required';
  }
}
