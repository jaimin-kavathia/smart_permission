/// Rich outcome of a permission request flow.
///
/// Unlike the boolean returned by `SmartPermission.request`, this tells you
/// *why* a request did not succeed so you can react appropriately:
/// ```dart
/// final result = await SmartPermission.requestResult(
///   permission: Permission.camera,
///   context: context,
/// );
/// if (result.canProceed) {
///   openCamera();
/// } else if (result == SmartPermissionResult.permanentlyDenied) {
///   // Offer a settings shortcut somewhere in your UI.
/// }
/// ```
enum SmartPermissionResult {
  /// The permission was granted.
  granted,

  /// The user granted limited access (e.g. selected photos on iOS 14+ /
  /// Android 14+). Usually enough to proceed.
  limited,

  /// The app is provisionally authorized (iOS provisional notifications).
  /// Usually enough to proceed.
  provisional,

  /// The user denied the permission (can be asked again).
  denied,

  /// The permission is permanently denied; only the app settings can
  /// change it.
  permanentlyDenied,

  /// The OS restricts this permission (e.g. parental controls). Neither the
  /// user nor the app can change it from within the app.
  restricted,

  /// The underlying platform call threw an error. See
  /// `SmartPermission.config.onError` to observe the exception.
  error;

  /// True only for [granted].
  bool get isGranted => this == granted;

  /// True when the feature can be used: [granted], [limited], or
  /// [provisional]. This is what the boolean `SmartPermission.request`
  /// API returns.
  bool get canProceed =>
      this == granted || this == limited || this == provisional;

  /// True when only the app settings can change the status.
  bool get isPermanentlyDenied => this == permanentlyDenied;
}
