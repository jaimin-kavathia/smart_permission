# smart_permission

<p align="center">
  <a href="https://pub.dev/packages/smart_permission"><img src="https://img.shields.io/pub/v/smart_permission.svg?label=pub.dev&color=blueviolet&logo=dart" alt="Pub.dev Badge"></a>
  <a href="https://github.com/jaimin-kavathia/smart_permission/actions/workflows/ci.yml"><img src="https://github.com/jaimin-kavathia/smart_permission/actions/workflows/ci.yml/badge.svg" alt="Build Badge"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-Flutter-ff69b4.svg" alt="Flutter Badge">
</p>

<p align="center">
  <strong>Flutter runtime permissions made easy.</strong><br/>
  <em>One-line requests, adaptive dialogs, and the complete permission flow (from first ask to "Open Settings") built on <a href="https://pub.dev/packages/permission_handler">permission_handler</a>.</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jaimin-kavathia/smart_permission/main/assets/images/smart_permission.png" alt="Smart Permission" width="100%">
</p>

---

## Contents

- [Why smart_permission?](#why-smart_permission)
- [Platform support](#platform-support)
- [Installation](#installation)
- [Platform setup](#platform-setup)
- [Quick start](#quick-start)
- [How the request flow works](#how-the-request-flow-works)
- [Usage](#usage)
- [PermissionGate](#permissiongate)
- [Customization](#customization)
- [Analytics](#analytics)
- [Error reporting](#error-reporting)
- [Testing](#testing)
- [Example app](#example-app)
- [Tips and notes](#tips-and-notes)
- [Upgrading](#upgrading)

---

## Why smart_permission?

Asking for a permission is easy; handling everything that can happen next is
not. The user may deny once, deny forever, be blocked by parental controls, or
change their mind in the system settings. `smart_permission` handles all of
it with one call, shows the right dialog at each step, and tells you exactly
how it ended.

| Feature                  | What you get                                                                  |
| :----------------------- | :---------------------------------------------------------------------------- |
| 🔐 One-line requests     | `SmartPermission.request()` for one permission, `requestMultiple()` for many  |
| 🧭 Complete flow         | Denied, permanently denied, and restricted handled automatically              |
| 🎯 Rich results          | `SmartPermissionResult` tells you *why* a request didn't succeed              |
| 🚪 PermissionGate        | A widget that shows its content only while a permission is usable             |
| 🔍 Silent checks         | `status()` and `hasPermission()` never prompt the user                        |
| ⚙️ Settings round trip   | Opens Settings, waits for the user to come back, then re-checks               |
| 💬 Rationale first       | Optionally explain *before* the one-shot native prompt                        |
| 🎨 Adaptive dialogs      | Material, Cupertino, or adaptive; light/dark and your brand color             |
| 🌍 Localization          | Every built-in string, title, and description can be replaced                 |
| 🧩 Custom dialogs        | Swap in your own dialog or bottom sheet                                       |
| 📊 Analytics hooks       | requested / granted / denied / permanently denied / restricted                |
| 🧪 Testable              | Ships `FakeSmartPermissionGateway` for widget tests without platform channels |

`Permission` and `PermissionStatus` are re-exported, so one import is enough.

---

## Platform support

| Android | iOS | Web (incl. WASM) | Windows | macOS | Linux |
| :-----: | :-: | :--------------: | :-----: | :---: | :---: |
|   ✅    | ✅  |        ✅        |   ✅    |  ❌   |  ❌   |

macOS and Linux are not supported because the underlying
[`permission_handler`](https://pub.dev/packages/permission_handler) plugin has
no implementation for them.

---

## Installation

```yaml
dependencies:
  smart_permission: ^1.1.0
```

```dart
import 'package:smart_permission/smart_permission.dart';
```

**Requirements:** Flutter 3.27+ (Dart 3.6+).

---

## Platform setup

The operating system only grants permissions that your app declares. Skipping
this step is the most common reason a request is denied silently.

### Android

1. Declare each permission in `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <uses-permission android:name="android.permission.CAMERA" />
       <uses-permission android:name="android.permission.RECORD_AUDIO" />
       <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
       <!-- ... -->
   </manifest>
   ```

2. Build with **compileSdk 37** (required by `permission_handler` 13). In
   `android/app/build.gradle(.kts)`:

   ```kotlin
   android {
       compileSdk = 37
       // ...
   }
   ```

### iOS

1. Add a usage description to `ios/Runner/Info.plist` for each permission.
   iOS shows this text in its own prompt:

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need the camera to scan QR codes.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need the microphone for voice notes.</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We use your location to show nearby stores.</string>
   ```

2. **CocoaPods only:** enable the same permissions in `ios/Podfile`
   (permissions are compiled out by default):

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'PERMISSION_CAMERA=1',
           'PERMISSION_MICROPHONE=1',
           'PERMISSION_LOCATION=1',
         ]
       end
     end
   end
   ```

   With Swift Package Manager this step is not needed: permissions are
   enabled from the `Info.plist` keys above.

See the
[permission_handler setup guide](https://pub.dev/packages/permission_handler#setup)
for the full list of manifest entries, `Info.plist` keys, and Podfile macros.

---

## Quick start

**Request a permission:** the right dialogs are shown automatically.

```dart
final granted = await SmartPermission.request(
  context,
  permission: Permission.camera,
  description: 'We need the camera to scan QR codes.',
);
if (granted) openScanner();
```

**Guard a screen:** the content appears once the permission is usable.

```dart
PermissionGate(
  permission: Permission.camera,
  description: 'We need the camera to scan QR codes.',
  builder: (context) => const QrScanner(),
)
```

**Check without asking:** no prompt, no dialog.

```dart
if (await SmartPermission.hasPermission(Permission.camera)) openScanner();
```

---

## How the request flow works

| Situation              | What the user sees                                                    |
| :--------------------- | :-------------------------------------------------------------------- |
| **Already allowed**    | Nothing; returns immediately                                          |
| **First time**         | The native system prompt (optionally after your explanation)          |
| **Denied**             | An explanation dialog offering to ask again                           |
| **Permanently denied** | An "Open Settings" dialog; waits for the user to return, then re-checks |
| **Restricted**         | An informational dialog (e.g. parental controls; Settings can't help) |

---

## Usage

### Know why a request failed

`requestResult` runs the same flow as `request` but returns a
`SmartPermissionResult` instead of a `bool`:

```dart
final result = await SmartPermission.requestResult(
  context: context,
  permission: Permission.camera,
);

if (result.canProceed) {
  openCamera();
} else if (result == SmartPermissionResult.permanentlyDenied) {
  showSettingsShortcut(); // e.g. a button calling SmartPermission.openSettings()
} else if (result == SmartPermissionResult.restricted) {
  hideCameraFeature(); // blocked by the device; nobody can change it in-app
} else {
  // denied or error: you can ask again later
}
```

| Result              | Meaning                                                   | `canProceed` |
| :------------------ | :-------------------------------------------------------- | :----------: |
| `granted`           | Full access                                               |      ✅      |
| `limited`           | Partial access, e.g. selected photos only                 |      ✅      |
| `provisional`       | iOS provisional notifications                             |      ✅      |
| `denied`            | Not granted this time; you may ask again                  |      ❌      |
| `permanentlyDenied` | Only the system settings can change it                    |      ❌      |
| `restricted`        | Blocked by the OS (e.g. parental controls)                |      ❌      |
| `error`             | The platform call failed (see [Error reporting](#error-reporting)) |      ❌      |

### Request several permissions

```dart
final results = await SmartPermission.requestMultiple(
  context,
  permissions: [Permission.camera, Permission.microphone],
);
// {Permission.camera: true, Permission.microphone: false}
```

The native prompts run as one batch, followed by at most one combined
explanation dialog and one combined settings dialog, never a dialog per
permission. Use `requestMultipleResults` to get a `SmartPermissionResult`
per permission.

### Explain before the native prompt

On iOS you can only show the native prompt once, so explaining first is
recommended:

```dart
// For one call:
await SmartPermission.request(
  context,
  permission: Permission.camera,
  showRationaleFirst: true,
);

// For every call:
SmartPermission.config.showRationaleBeforeRequest = true;
```

### Request without a BuildContext

Useful from services, view models, or blocs:

```dart
final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(navigatorKey: navigatorKey, ...);
SmartPermission.config.navigatorKey = navigatorKey;

// Anywhere:
final result = await SmartPermission.requestResult(
  permission: Permission.camera,
);
```

Without a context or navigator key, only the native prompt is shown (no
dialogs).

### Check without asking

These never prompt and never show a dialog:

```dart
final usable = await SmartPermission.hasPermission(Permission.camera);
final result = await SmartPermission.status(Permission.location);
final all = await SmartPermission.statuses([
  Permission.camera,
  Permission.microphone,
]);

// Open this app's settings page (returns false where unsupported, e.g. web).
await SmartPermission.openSettings();
```

> **Android:** the OS reveals a *permanent* denial only in response to a
> request. `status()` therefore reports `permanentlyDenied` once a request in
> the current app session has found it, and `denied` before that.

---

## PermissionGate

`PermissionGate` shows its content only while a permission is usable
(granted, limited, or provisional). Otherwise it shows a fallback with a call
to action:

- **Allow** runs the full request flow.
- **Open Settings** appears when the permission is permanently denied.
- A restricted permission gets an explanation and no button.

The gate re-checks whenever the app returns to the foreground, so changes made
in the system settings show up immediately.

```dart
PermissionGate(
  permission: Permission.camera,
  description: 'We need the camera to scan QR codes.',
  builder: (context) => const QrScanner(),
)
```

| Parameter            | Purpose                                                                |
| :------------------- | :--------------------------------------------------------------------- |
| `builder`            | The protected content (required)                                       |
| `fallbackBuilder`    | Your own "not allowed" UI: `(context, result, request) => ...`         |
| `loadingBuilder`     | Shown during the first check (default: nothing)                        |
| `requestOnMount`     | Start the request flow as soon as the gate appears                     |
| `onChanged`          | Called with the new `SmartPermissionResult` whenever it changes        |
| `style`              | Dialog style, also used for the default fallback's button              |
| `title`, `description`, `showRationaleFirst` | Passed to the dialogs and the default fallback |

A custom fallback receives the current result and a `request` callback that
does the right thing (request, or open settings when permanently denied):

```dart
PermissionGate(
  permission: Permission.microphone,
  fallbackBuilder: (context, result, request) {
    if (result == SmartPermissionResult.restricted) {
      return const Text('Voice notes are disabled on this device.');
    }
    return TextButton(
      onPressed: request,
      child: const Text('Enable voice notes'),
    );
  },
  builder: (context) => const VoiceRecorder(),
)
```

---

## Customization

Configure once at startup through `SmartPermission.config`, or change values
at runtime.

| Property                     | Purpose                                                           |
| :--------------------------- | :---------------------------------------------------------------- |
| `defaultDialogStyle`         | `adaptive` (default), `material`, or `cupertino`                  |
| `brightness`, `primaryColor` | Theme of the built-in dialogs                                     |
| `titleProvider`              | Per-permission titles                                             |
| `descriptionProvider`        | Per-permission descriptions                                       |
| `strings`                    | Every built-in string, for localization                           |
| `showRationaleBeforeRequest` | Explain before every native prompt                                |
| `navigatorKey`               | Show dialogs without passing a `BuildContext`                     |
| `customDialogBuilder`        | Replace the built-in dialogs entirely                             |
| `analytics`                  | Receive flow events                                               |
| `onError`                    | Observe platform and dialog errors                                |
| `gateway`                    | Platform access; replace with a fake in tests                     |

`SmartPermission.config.resetToDefaults()` restores everything (handy in
tests).

### Theme

```dart
SmartPermission.config
  ..defaultDialogStyle = PermissionDialogStyle.adaptive
  ..brightness = Brightness.dark
  ..primaryColor = Colors.indigo;
```

### Texts per permission

Built-in titles and descriptions exist for every permission. Override the
ones you need; return `null` to keep the built-in text:

```dart
SmartPermission.config
  ..titleProvider = (p) {
    if (p == Permission.camera) return 'Camera access needed';
    return null;
  }
  ..descriptionProvider = (p) {
    if (p == Permission.camera) return 'We need the camera to scan QR codes.';
    if (p == Permission.microphone) return 'We need the microphone for voice notes.';
    return null;
  };
```

A `title` or `description` passed to a call always wins over the providers.

### Localization

Replace any built-in string; the ones you leave out keep their English
default:

```dart
SmartPermission.config.strings = const SmartPermissionStrings(
  allow: 'Autoriser',
  notNow: 'Plus tard',
  cancel: 'Annuler',
  openSettings: 'Ouvrir les réglages',
  blockedMessage: 'Autorisation désactivée. Activez-la dans les réglages.',
);
```

Combine with `titleProvider` and `descriptionProvider` (for example backed by
your `AppLocalizations`) to translate the per-permission texts.

### Custom dialog

Use your own UI, such as a bottom sheet. Return `true` for the primary
action:

```dart
SmartPermission.config.customDialogBuilder = (
  context, {
  required style,
  required title,
  required message,
  required primaryText,
  required secondaryText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(primaryText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(secondaryText),
          ),
        ],
      ),
    ),
  );
};
```

---

## Analytics

Extend `PermissionAnalyticsTracker` and override only the hooks you need.
Use `extends`, not `implements`, so future hooks don't break your class:

```dart
class MyAnalytics extends PermissionAnalyticsTracker {
  @override
  void onRequested(Permission permission) => log('requested $permission');

  @override
  void onGranted(Permission permission) => log('granted $permission');

  @override
  void onDenied(Permission permission) => log('denied $permission');

  @override
  void onPermanentlyDenied(Permission permission) => log('blocked $permission');

  @override
  void onRestricted(Permission permission) => log('restricted $permission');
}

SmartPermission.config.analytics = MyAnalytics();
```

The default `InMemoryPermissionAnalyticsTracker` counts each event per
permission, which is handy while debugging.

---

## Error reporting

Platform failures are logged with `debugPrint` and returned as
`SmartPermissionResult.error`, so they never crash your app. Forward them to
your crash reporter:

```dart
SmartPermission.config.onError = (error, stack) =>
    FirebaseCrashlytics.instance.recordError(error, stack);
```

---

## Testing

Test your permission UX without devices or platform channels using
`FakeSmartPermissionGateway` from `package:smart_permission/testing.dart`:

```dart
import 'package:smart_permission/testing.dart';

testWidgets('scanner unlocks after allowing the camera', (tester) async {
  final fake = FakeSmartPermissionGateway()
    ..requestResults[Permission.camera] = [PermissionStatus.granted];
  SmartPermission.config.gateway = fake;
  addTearDown(SmartPermission.config.resetToDefaults);

  await tester.pumpWidget(const MyApp());
  await tester.tap(find.text('Allow'));
  await tester.pumpAndSettle();

  expect(fake.requestedPermissions, [Permission.camera]);
  expect(find.byType(QrScanner), findsOneWidget);
});
```

| Fake member                  | Use it to                                                        |
| :--------------------------- | :--------------------------------------------------------------- |
| `statuses`                   | Set the current status per permission (default: `denied`)        |
| `requestResults`             | Queue what each successive request returns                       |
| `statusesAfterSettings`      | Simulate what the user changed in the system settings            |
| `canOpenSettings`            | Simulate a platform that can't open settings (e.g. web)          |
| `statusError`, `requestError` | Make status checks or requests throw                            |
| `androidStatusSemantics`     | Mimic Android, where a permanent denial is only visible from a request |
| `requestedPermissions`       | Assert which permissions were requested, in order                |
| `openSettingsCalls`          | Assert how often settings were opened                            |

For anything else, implement `SmartPermissionGateway` yourself.

---

## Example app

The [`example`](https://github.com/jaimin-kavathia/smart_permission/tree/main/example)
app demonstrates:

- Single and batch requests with live results
- `PermissionGate` guarding a camera card
- Material, Cupertino, and adaptive dialog styles
- Light/dark theme and primary color switching
- Custom per-permission texts
- A custom bottom-sheet dialog
- A live analytics panel

---

## Tips and notes

- Some Android permissions (`manageExternalStorage`, `systemAlertWindow`,
  `requestInstallPackages`) open a system settings page instead of a dialog.
- On Android 13+, use `Permission.photos`, `Permission.videos`, or
  `Permission.audio` instead of the deprecated storage permissions.
- Request `locationWhenInUse` before `locationAlways`. Android 11+ requires
  that order, and it is the recommended order on iOS.
- Android 17's `Permission.accessLocalNetwork` is supported with built-in
  texts; declare `android.permission.ACCESS_LOCAL_NETWORK` in your manifest.
- On web, browsers decide when to show prompts, and settings cannot be opened
  from the app.

---

## Upgrading

### To 1.1

Only additions: `PermissionGate`, `status` / `statuses` / `hasPermission`,
`openSettings`, and `package:smart_permission/testing.dart`. No code changes
needed.

### To 1.0.2

- Requires Flutter 3.27+ / Dart 3.6+ (earlier versions could not compile the
  package anyway).
- A `titleProvider` or `descriptionProvider` that returns `null` now falls
  back to the built-in text instead of a generic message.
- On Android, repeat requests for an already blocked permission skip the
  explanation dialog and go straight to "Open Settings".

### From 0.x to 1.0

`request(...)` and `requestMultiple(...)` keep their signatures and return
types. Notes:

- **Android:** `permission_handler` 13 requires building with compileSdk 37.
- **Analytics:** if your tracker used `implements PermissionAnalyticsTracker`,
  switch to `extends` (new hooks: `onRequested`, `onGranted`, `onRestricted`).
- **Behavior:** `requestMultiple` runs one native batch with combined dialogs
  instead of a full flow per permission, and the settings flow waits for the
  user to return before re-checking.

The full history is in the [changelog](CHANGELOG.md).

---

## Author

Created by [**Jaimin Kavathia**](https://jaimin-kavathia.github.io/) ·
[LinkedIn](https://in.linkedin.com/in/jaimin-kavathia-flutter-developer) ·
[GitHub](https://github.com/jaimin-kavathia)

Issues and pull requests are welcome on
[GitHub](https://github.com/jaimin-kavathia/smart_permission/issues).

## License

[MIT](LICENSE): free for personal and commercial use.

---

<p align="center">
  ⭐ <strong>If smart_permission saves you time, give it a like on <a href="https://pub.dev/packages/smart_permission">pub.dev</a> and a star on <a href="https://github.com/jaimin-kavathia/smart_permission">GitHub</a>!</strong>
</p>
