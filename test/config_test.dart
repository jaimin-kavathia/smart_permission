import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';

void main() {
  group('SmartPermissionConfig resolvers', () {
    test('falls back to built-in defaults when no providers/overrides', () {
      // Ensure clean config
      SmartPermission.config
        ..titleProvider = null
        ..descriptionProvider = null;

      // Camera should have defaults
      expect(
        SmartPermission.config.resolveTitle(Permission.camera, null),
        isNotNull,
      );
      expect(
        SmartPermission.config.resolveDescription(Permission.camera, null),
        isNotNull,
      );
    });

    test('explicit description takes precedence over provider/default', () {
      SmartPermission.config.titleProvider = (p) => 'Title from provider';
      SmartPermission.config.descriptionProvider = (p) => 'Desc from provider';

      final title = SmartPermission.config
          .resolveTitle(Permission.photos, 'Explicit Title');
      final desc = SmartPermission.config
          .resolveDescription(Permission.photos, 'Explicit Desc');

      expect(title, 'Explicit Title');
      expect(desc, 'Explicit Desc');
    });

    test('provider used when explicit is null and overrides default', () {
      SmartPermission.config.titleProvider =
          (p) => p == Permission.microphone ? 'Mic Title' : null;
      SmartPermission.config.descriptionProvider =
          (p) => p == Permission.microphone ? 'Mic Desc' : null;

      final title =
          SmartPermission.config.resolveTitle(Permission.microphone, null);
      final desc = SmartPermission.config
          .resolveDescription(Permission.microphone, null);

      expect(title, 'Mic Title');
      expect(desc, 'Mic Desc');
    });
  });

  group('InMemoryPermissionAnalyticsTracker', () {
    test('increments denied and permanentlyDenied counters', () {
      final tracker = InMemoryPermissionAnalyticsTracker();

      tracker.onDenied(Permission.camera);
      tracker.onDenied(Permission.camera);
      tracker.onPermanentlyDenied(Permission.location);

      expect(tracker.deniedCounts[Permission.camera], 2);
      expect(tracker.permanentlyDeniedCounts[Permission.location], 1);
    });
  });
}
