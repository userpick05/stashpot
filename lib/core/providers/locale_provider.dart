import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

/// The locales the app ships. Chinese is declared as **zh-Hant-TW**, not bare
/// `zh`: flutter_localizations resolves bare `zh` to its SIMPLIFIED Material
/// translations (确定 / 选择日期), which would sit next to our Traditional strings
/// in every date picker and dialog. Declaring the script+country pulls the
/// Traditional Material strings instead. Our own generated delegate matches on
/// languageCode alone, so `app_zh.arb` still resolves.
const kChineseLocale =
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');

const kSupportedLocales = <Locale>[
  Locale('en'),
  kChineseLocale,
];

/// The user's language override. `null` means "follow the device locale",
/// which is the default — so a phone set to Chinese gets Chinese with no setup.
class LocaleController extends StateNotifier<Locale?> {
  /// [initial] is read in `main()` before the first frame so the app never
  /// paints in the wrong language and then flips.
  LocaleController([super.initial]);

  /// Reads the persisted override (null = follow the device locale).
  static Future<Locale?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(_prefsKey));
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, encode(locale));
    }
  }

  // All three subtags are stored — dropping the script/country would round-trip
  // zh-Hant-TW back to bare `zh` and silently return to Simplified Material
  // strings on the next launch.
  static String encode(Locale l) =>
      [l.languageCode, l.scriptCode ?? '', l.countryCode ?? ''].join('|');

  static Locale? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    if (s.contains('|')) {
      final p = s.split('|');
      return Locale.fromSubtags(
        languageCode: p[0],
        scriptCode: p.length > 1 && p[1].isNotEmpty ? p[1] : null,
        countryCode: p.length > 2 && p[2].isNotEmpty ? p[2] : null,
      );
    }
    // Legacy values ('en', 'zh', 'zh_Hant') written before this format.
    final lang = s.split('_').first;
    return lang == 'zh' ? kChineseLocale : Locale(lang);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleController, Locale?>((ref) => LocaleController());
