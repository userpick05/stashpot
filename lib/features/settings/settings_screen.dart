import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_version.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/widgets/invite_code_sheet.dart';
import 'manage_locations_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final code = ref.watch(householdIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── About ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              children: [
                Icon(Icons.kitchen, size: 48, color: scheme.primary),
                const SizedBox(height: 8),
                Text('Stashpot',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                Text('Your home pantry, always in sync',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('Version $kAppVersion',
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
            title: const Text('Invite friends'),
            subtitle: const Text('Share your household invite code'),
            onTap: code == null ? null : () => showInviteCodeSheet(context, code),
          ),

          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Pantry locations'),
            subtitle: const Text('Add or edit your own storage locations'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageLocationsScreen()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
