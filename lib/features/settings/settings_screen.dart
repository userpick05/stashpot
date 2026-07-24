import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_version.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/invite_code_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'manage_locations_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Language picker. A bottom sheet rather than an AlertDialog — dialogs
  /// black-screen via Impeller on some devices.
  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // `null` = follow the device locale.
    final options = <(Locale?, String)>[
      (null, l.languageSystem),
      (const Locale('en'), l.languageEnglish),
      // zh-Hant-TW, not bare zh — see kChineseLocale (Simplified Material strings).
      (kChineseLocale, l.languageChineseTraditional),
    ];
    final current = ref.read(localeProvider)?.languageCode;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(l.settingsLanguage,
                    style: Theme.of(ctx).textTheme.titleLarge),
              ),
              for (final (locale, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: current == locale?.languageCode
                      ? Icon(Icons.check,
                          color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(locale);
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(appUserProvider).valueOrNull;
    final code = ref.watch(householdIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          // ── About ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              children: [
                Icon(Icons.kitchen, size: 48, color: scheme.primary),
                const SizedBox(height: 8),
                Text(l.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                Text(l.appTagline,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(l.settingsVersion(kAppVersion),
                    style: TextStyle(color: scheme.outline, fontSize: 12)),
              ],
            ),
          ),
          const Divider(),

          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.displayName),
              subtitle: Text(user.email),
            ),

          ListTile(
            leading: const Icon(Icons.person_add),
            title: Text(l.settingsInviteFriends),
            subtitle: Text(l.settingsInviteSubtitle),
            onTap: code == null ? null : () => showInviteCodeSheet(context, code),
          ),

          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(l.settingsPantryLocations),
            subtitle: Text(l.settingsPantryLocationsSubtitle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageLocationsScreen()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            subtitle: Text(l.settingsLanguageSubtitle),
            onTap: () => _showLanguageSheet(context, ref),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l.settingsSignOut,
                style: const TextStyle(color: Colors.red)),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
