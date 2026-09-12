import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Bridge to the Android home-screen quick-add widget.
///
/// The widget itself is native (Kotlin `StashpotWidgetProvider`); this pushes
/// the display strings into it and its tap surfaces as a launch of the app.
/// The text is formatted here (with the app's localization) so the widget
/// follows whatever language the app is set to. All calls are Android-only and
/// fail soft — the widget is a convenience, never something the app relies on.
class QuickAddWidget {
  static const _androidName = 'StashpotWidgetProvider';

  /// The URI the native widget launches the app with when tapped.
  static const launchUri = 'stashpot://quickadd';

  /// Push the (already-localized) count line and button label, then repaint.
  static Future<void> setText({
    required String countText,
    required String addLabel,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await HomeWidget.saveWidgetData<String>('count_text', countText);
      await HomeWidget.saveWidgetData<String>('add_label', addLabel);
      await HomeWidget.updateWidget(
          name: _androidName, androidName: _androidName);
    } catch (_) {
      // A missing widget / platform hiccup must never break the app.
    }
  }
}
