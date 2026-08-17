# 🧠 smart_permission

<p align="center">
  <a href="https://pub.dev/packages/smart_permission"><img src="https://img.shields.io/pub/v/smart_permission.svg?label=pub.dev&color=blueviolet&logo=dart" alt="Pub.dev Badge"></a>
  <a href="https://github.com/jaimin-kavathia/smart_permission/actions/workflows/ci.yml"><img src="https://github.com/jaimin-kavathia/smart_permission/actions/workflows/ci.yml/badge.svg" alt="Build Badge"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-Flutter-ff69b4.svg" alt="Flutter Badge">
</p>

<p align="center">
  <strong>🚀 An opinionated wrapper around <a href="https://pub.dev/packages/permission_handler">permission_handler</a> that makes runtime permissions effortless.</strong><br/>
  <em>Request permissions with one API — smart dialogs, adaptive styles, and complete UX flow handling built-in.</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jaimin-kavathia/smart_permission/main/assets/images/smart_permission.png" alt="Smart Permission" width="100%">
</p>

---

## ✨ Why smart_permission?

Most apps spend unnecessary time handling permission logic manually.
`smart_permission` takes care of the entire flow — from **first ask to permanently denied** — automatically, with adaptive dialogs and analytics tracking.

### 💡 What makes it different?

- ✅ One-line permission requests (single or batch)
- ✅ Handles **denied** and **permanently denied** flows automatically
- ✅ Adaptive **Material / Cupertino / Adaptive** dialogs
- ✅ Built-in titles & descriptions (with custom overrides)
- ✅ Global **theming**, **analytics hooks**, and **custom dialogs**
- ✅ Re-exports `Permission` — no need for multiple imports

---

## 🧩 Feature Highlights

| Feature                        | Description                                             |
| :----------------------------- | :------------------------------------------------------ |
| 🔐 Easy API                    | `SmartPermission.request()` for one or many permissions |
| 🎨 Adaptive Dialogs            | Material / Cupertino / Platform adaptive support        |
| 🧭 Auto Flows                  | Handles denied/permanently denied states automatically  |
| 🧱 Central Configuration       | Set global themes, titles, descriptions, analytics      |
| 🧩 Custom Dialog Builders      | Build your own dialog UI if you need full control       |
| 🧠 In-Memory Analytics Tracker | Tracks denied and permanently denied permissions        |

---

## 🖥️ Platform Support

| Android | iOS | Web (incl. WASM) | Windows | macOS | Linux |
| :-----: | :-: | :--------------: | :-----: | :---: | :---: |
|   ✅    | ✅  |        ✅        |   ✅    |  ❌   |  ❌   |

macOS and Linux are not supported because the underlying
[`permission_handler`](https://pub.dev/packages/permission_handler) plugin has
no implementation for them.

---

## ⚙️ Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_permission: ^1.0.0
```

> **Android note:** `smart_permission` 1.0.0+ depends on `permission_handler` 13,
> which requires your app to build with **compileSdk 37**. Flutter's default is
> still 36, so set it explicitly in `android/app/build.gradle(.kts)`:
>
> ```kotlin
> android {
>     compileSdk = 37
>     // ...
> }
> ```

Then import:

```dart
import 'package:smart_permission/smart_permission.dart';
```

---

## ⚡ Quick Start Example

```dart
final ok = await SmartPermission.request(
  context,
  permission: Permission.camera,
  style: PermissionDialogStyle.adaptive,
  description: 'We need camera to scan QR codes.',
);
```

Or request multiple:

```dart
final result = await SmartPermission.requestMultiple(
  context,
  permissions: [
    Permission.camera,
    Permission.microphone,
  ],
);
```

### Automatic Dialog Flow

| State                  | Behavior                                                      |
| :--------------------- | :------------------------------------------------------------ |
| **First time**         | Shows native system sheet (optionally after a rationale)      |
| **Denied**             | Shows rationale dialog with retry                             |
| **Permanently denied** | Shows “Open Settings” dialog, waits for return, re-checks     |
| **Restricted**         | Shows an informational dialog (settings can't fix restricted) |

### Need to know *why* it failed? Use the result API

```dart
final result = await SmartPermission.requestResult(
  context: context,
  permission: Permission.camera,
);

switch (result) {
  case SmartPermissionResult.granted:
  case SmartPermissionResult.limited:
  case SmartPermissionResult.provisional:
    openCamera(); // or just check result.canProceed
  case SmartPermissionResult.permanentlyDenied:
    // Show a settings shortcut somewhere in your UI.
  case SmartPermissionResult.restricted:
    // Blocked by the OS (e.g. parental controls).
  case SmartPermissionResult.denied:
  case SmartPermissionResult.error:
    // Try again later.
}
```

`requestMultipleResults` does the same for batches — one native batch flow,
one combined rationale dialog, and one combined settings dialog instead of a
dialog per permission.

### Explain *before* the native prompt (recommended)

On iOS you only get one native ask — explain first:

```dart
// Per call:
await SmartPermission.request(context,
    permission: Permission.camera, showRationaleFirst: true);

// Or globally:
SmartPermission.config.showRationaleBeforeRequest = true;
```

### No BuildContext? Use a navigator key

```dart
final navKey = GlobalKey<NavigatorState>();

MaterialApp(navigatorKey: navKey, ...);
SmartPermission.config.navigatorKey = navKey;

// Anywhere, without a context:
final result = await SmartPermission.requestResult(
  permission: Permission.camera,
);
```

---

## 🎨 Configuration & Customization

You can configure `SmartPermission` globally at app startup or dynamically at runtime.

### Global Setup

```dart
SmartPermission.config
  ..brightness = Brightness.light
  ..primaryColor = Colors.indigo
  ..analytics = InMemoryPermissionAnalyticsTracker();
```

### Toggle Theme & Primary Color (as in example app)

```dart
SmartPermission.config.brightness =
    isDark ? Brightness.dark : Brightness.light;

SmartPermission.config.primaryColor = selectedPrimaryColor;
```

---

## 🧠 Custom Texts Per Permission

Provide your own titles and messages for each permission:

```dart
SmartPermission.config
  ..titleProvider = (p) {
    if (p == Permission.camera) return 'Camera Access Needed';
    if (p == Permission.microphone) return 'Microphone Access Needed';
    if (p == Permission.locationWhenInUse) return 'Location Access Needed';
    return null;
  }
  ..descriptionProvider = (p) {
    if (p == Permission.camera) return 'We need the camera to scan QR codes.';
    if (p == Permission.microphone) return 'We need the microphone for voice features.';
    if (p == Permission.locationWhenInUse) return 'We use your location to show nearby stores.';
    return null;
  };
```

---

## 🧩 Custom Dialog Builder

Want your own UI (like a bottom sheet)?
You can override the default dialog completely.

```dart
SmartPermission.config.customDialogBuilder = (
  context, {
  required style,
  required title,
  required message,
  required primaryText,
  required secondaryText,
}) async {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.privacy_tip_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(secondaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
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
};
```

---

## 🌍 Localization

Every built-in string can be replaced (unset ones keep their English default):

```dart
SmartPermission.config.strings = const SmartPermissionStrings(
  allow: 'Autoriser',
  notNow: 'Plus tard',
  openSettings: 'Ouvrir les réglages',
  blockedMessage: 'Autorisation désactivée. Activez-la dans les réglages.',
);
```

Combine with `titleProvider`/`descriptionProvider` for localized
per-permission texts.

---

## 📊 Analytics Tracking

Track user behavior for better insights or debugging. Extend
`PermissionAnalyticsTracker` (don't implement it) so future hooks won't break
your tracker:

```dart
class MyAnalytics extends PermissionAnalyticsTracker {
  @override
  void onRequested(Permission permission) => log('requested: $permission');

  @override
  void onGranted(Permission permission) => log('granted: $permission');

  @override
  void onDenied(Permission permission) => log('denied: $permission');

  @override
  void onPermanentlyDenied(Permission permission) => log('blocked: $permission');

  @override
  void onRestricted(Permission permission) => log('restricted: $permission');
}

SmartPermission.config.analytics = MyAnalytics();
```

The example app uses a small tracker to log permission denials in real-time within the UI.

---

## 🚨 Error Reporting

Platform-call failures are logged with `debugPrint` and surface as
`SmartPermissionResult.error`. Forward them to your crash reporter:

```dart
SmartPermission.config.onError = (error, stack) =>
    FirebaseCrashlytics.instance.recordError(error, stack);
```

---

## 🧪 Testing Your Permission Flows

Widget-test your app's permission UX without platform channels by swapping the
gateway:

```dart
class FakeGateway implements SmartPermissionGateway {
  // Return whatever statuses your test needs...
}

SmartPermission.config.gateway = FakeGateway();
// ...run your flow, then:
SmartPermission.config.resetToDefaults();
```

---

## 🧩 Example App Features

The included `/example` project demonstrates:

- 🔄 Theme toggle (Light/Dark)
- 🎨 Primary color cycling (Indigo / Teal / Orange)
- 📱 Dialog style selection (Material, Cupertino, Adaptive)
- 🧠 Custom title/description per permission
- 🪟 Custom bottom-sheet dialog builder
- 📊 Real-time analytics tracking for denied states
- 📦 Batch permission requests

---

## 🧠 Tips & Notes

- Some Android permissions (e.g., `manageExternalStorage`, `systemAlertWindow`) open system settings instead of a dialog.
- Android 17 adds `Permission.accessLocalNetwork` (declare `android.permission.ACCESS_LOCAL_NETWORK` in your manifest) — supported out of the box with built-in dialog texts.
- On Android 13+, use `Permission.photos`, `Permission.videos`, or `Permission.audio` instead of deprecated storage permissions.
- `locationAlways` often requires first granting `locationWhenInUse`.
- Use `SmartPermission.requestMultiple()` for grouped requests.

---

## 🔀 Migrating from 0.x

1.0.0 keeps the 0.x API working — `request(...)` and `requestMultiple(...)`
have the same signatures and return types. Notes:

- **Android**: `permission_handler` 13 requires building with `compileSdk 37`.
- **Analytics**: if your tracker used `implements PermissionAnalyticsTracker`,
  switch to `extends` (new hooks were added: `onRequested`, `onGranted`,
  `onRestricted`).
- **Behavior**: `requestMultiple` now runs one native batch flow with combined
  dialogs instead of a full dialog flow per permission; the settings flow now
  waits for the user to return from Settings before re-checking (previously it
  re-checked immediately and usually reported `false`).
- **New APIs** (opt-in): `requestResult`, `requestMultipleResults`,
  `SmartPermissionResult`, `SmartPermissionStrings`, `showRationaleFirst`,
  `config.navigatorKey`, `config.onError`, `config.gateway`.

---

## 👤 Author

Created with ❤️ by [**Jaimin Kavathia**](https://jaimin-kavathia.github.io/)
💼 [LinkedIn](https://in.linkedin.com/in/jaimin-kavathia-flutter-developer) • 🐙 [GitHub](https://github.com/jaimin-kavathia)

---

## 📜 License

Licensed under the [**MIT License**](LICENSE).
Free for personal and commercial use.

---

<p align="center">
  ⭐ <strong>If you like this package, give it a star on <a href="https://github.com/jaimin-kavathia/smart_permission">GitHub</a> & <a href="https://pub.dev/packages/smart_permission">pub.dev</a>!</strong>
</p>

<p align="center">
  <em>smart_permission — because handling permissions shouldn’t be a hassle.</em>
</p>
