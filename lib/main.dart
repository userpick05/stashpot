import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Needed so DateFormat can render non-English locales (planner dates).
  await initializeDateFormatting();
  // Read the saved language override BEFORE the first frame, otherwise the app
  // paints one frame in the device locale and then visibly flips.
  final savedLocale = await LocaleController.loadSaved();
  runApp(ProviderScope(
    overrides: [localeProvider.overrideWith((ref) => LocaleController(savedLocale))],
    child: const StashpotApp(),
  ));
}

class StashpotApp extends ConsumerWidget {
  const StashpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // null = follow the device locale; set = the user's explicit override.
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Stashpot',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: kSupportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
