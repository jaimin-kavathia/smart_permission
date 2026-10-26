/// Test helpers for apps using smart_permission.
///
/// ```dart
/// import 'package:smart_permission/testing.dart';
///
/// SmartPermission.config.gateway = FakeSmartPermissionGateway(
///   statuses: {Permission.camera: PermissionStatus.granted},
/// );
/// ```
library;

export 'src/testing/fake_smart_permission_gateway.dart';
