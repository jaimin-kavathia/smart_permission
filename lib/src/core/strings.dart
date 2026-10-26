/// All user-facing strings used by the built-in dialogs.
///
/// Every string has an English default. To localize, assign a new instance
/// with only the strings you want to change (unset ones keep their default):
/// ```dart
/// SmartPermission.config.strings = const SmartPermissionStrings(
///   allow: 'Autoriser',
///   notNow: 'Plus tard',
///   openSettings: 'Ouvrir les réglages',
/// );
/// ```
/// Messages containing `{permissions}` or `{permission}` are templates; the
/// placeholder is replaced at display time.
class SmartPermissionStrings {
  /// Creates a set of strings; any string not passed keeps its English
  /// default.
  const SmartPermissionStrings({
    this.allow = 'Allow',
    this.notNow = 'Not now',
    this.cancel = 'Cancel',
    this.ok = 'OK',
    this.openSettings = 'Open Settings',
    this.permissionRequiredTitle = 'Permission required',
    this.permissionBlockedTitle = 'Permission blocked',
    this.permissionRestrictedTitle = 'Permission restricted',
    this.blockedMessage =
        'Permission is disabled. You can enable it in the app settings.',
    this.restrictedMessage =
        'This permission is restricted on this device (for example by '
            'parental controls) and cannot be enabled from the app.',
    this.openSettingsManuallyTitle = 'Open settings manually',
    this.openSettingsManuallyMessage =
        'We couldn\'t open settings automatically. Please enable this '
            'permission in your system or browser settings and return to '
            'the app.',
    this.multipleRationaleMessage =
        'This app needs the following permissions: {permissions}.',
    this.multipleBlockedMessage =
        'The following permissions are disabled: {permissions}. You can '
            'enable them in the app settings.',
    this.genericRationaleMessage =
        'This feature needs permission: {permission}.',
  });

  /// Primary button of the rationale dialog.
  final String allow;

  /// Secondary button of the rationale dialog.
  final String notNow;

  /// Secondary button of the settings and informational dialogs.
  final String cancel;

  /// Primary button of informational dialogs.
  final String ok;

  /// Primary button of the permanently-denied dialog.
  final String openSettings;

  /// Fallback title of the rationale dialog.
  final String permissionRequiredTitle;

  /// Fallback title of the permanently-denied dialog.
  final String permissionBlockedTitle;

  /// Fallback title of the restricted dialog.
  final String permissionRestrictedTitle;

  /// Appended to the description in the permanently-denied dialog.
  final String blockedMessage;

  /// Message of the restricted dialog.
  final String restrictedMessage;

  /// Title shown when app settings cannot be opened automatically.
  final String openSettingsManuallyTitle;

  /// Message shown when app settings cannot be opened automatically.
  final String openSettingsManuallyMessage;

  /// Template; `{permissions}` is replaced with a comma-separated list of
  /// permission titles.
  final String multipleRationaleMessage;

  /// Template; `{permissions}` is replaced with a comma-separated list of
  /// permission titles.
  final String multipleBlockedMessage;

  /// Template; `{permission}` is replaced with the permission name.
  final String genericRationaleMessage;

  /// [multipleRationaleMessage] with [permissions] filled in.
  String formatMultipleRationale(String permissions) =>
      multipleRationaleMessage.replaceAll('{permissions}', permissions);

  /// [multipleBlockedMessage] with [permissions] filled in.
  String formatMultipleBlocked(String permissions) =>
      multipleBlockedMessage.replaceAll('{permissions}', permissions);

  /// [genericRationaleMessage] with [permission] filled in.
  String formatGenericRationale(String permission) =>
      genericRationaleMessage.replaceAll('{permission}', permission);
}
