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

## ⚙️ Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_permission: ^0.0.1
```

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

| State                  | Behavior                     |
| :--------------------- | :--------------------------- |
| **First time**         | Shows native system sheet    |
| **Denied**             | Shows rationale dialog       |
| **Permanently denied** | Shows “Open Settings” dialog |

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

## 📊 Analytics Tracking

Track user behavior for better insights or debugging:

```dart
class MyAnalytics implements PermissionAnalyticsTracker {
  @override
  void onDenied(Permission permission) {
    print('Permission denied: $permission');
  }

  @override
  void onPermanentlyDenied(Permission permission) {
    print('Permission permanently denied: $permission');
  }
}

SmartPermission.config.analytics = MyAnalytics();
```

The example app uses `InMemoryPermissionAnalyticsTracker()` to log permission denials in real-time within the UI.

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
- On Android 13+, use `Permission.photos`, `Permission.videos`, or `Permission.audio` instead of deprecated storage permissions.
- `locationAlways` often requires first granting `locationWhenInUse`.
- Use `SmartPermission.requestMultiple()` for grouped requests.

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
