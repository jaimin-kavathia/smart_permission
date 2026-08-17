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

  final String allow;
  final String notNow;
  final String cancel;
  final String ok;
  final String openSettings;
  final String permissionRequiredTitle;
  final String permissionBlockedTitle;
  final String permissionRestrictedTitle;
  final String blockedMessage;
  final String restrictedMessage;
  final String openSettingsManuallyTitle;
  final String openSettingsManuallyMessage;

  /// Template; `{permissions}` is replaced with a comma-separated list of
  /// permission titles.
  final String multipleRationaleMessage;

  /// Template; `{permissions}` is replaced with a comma-separated list of
  /// permission titles.
  final String multipleBlockedMessage;

  /// Template; `{permission}` is replaced with the permission name.
  final String genericRationaleMessage;

  String formatMultipleRationale(String permissions) =>
      multipleRationaleMessage.replaceAll('{permissions}', permissions);

  String formatMultipleBlocked(String permissions) =>
      multipleBlockedMessage.replaceAll('{permissions}', permissions);

  String formatGenericRationale(String permission) =>
      genericRationaleMessage.replaceAll('{permission}', permission);
}
