/// Supported dialog styles for permission prompts.
enum PermissionDialogStyle {
  /// Material 3 `AlertDialog` on every platform.
  material,

  /// iOS-style `CupertinoAlertDialog` on every platform.
  cupertino,

  /// Cupertino on iOS and macOS, Material everywhere else.
  adaptive,
}
