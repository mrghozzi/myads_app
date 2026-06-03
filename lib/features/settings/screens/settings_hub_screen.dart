import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/safe_url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../profile/profile_provider.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  Future<void> _launchUrl(String url) async {
    await SafeUrlLauncher.launch(url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileDetailProvider('me'));
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Profile Summary
            Card(
              elevation: isDark ? 0 : 2,
              color: isDark ? const Color(0xFF222630) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user.avatar.isNotEmpty
                          ? NetworkImage(user.avatar)
                          : null,
                      child: user.avatar.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/settings/profile'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF615dfa)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(l10n.editProfile, style: const TextStyle(color: Color(0xFF615dfa))),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Group
            _buildSectionTitle('Account', isDark),
            _buildListTile(context, Icons.person, l10n.editProfile, '/settings/profile', isDark),
            _buildListTile(context, Icons.lock, l10n.privacy, '/settings/privacy', isDark),
            _buildListTile(context, Icons.share, l10n.socialLinks, '/settings/social', isDark),
            _buildListTile(context, Icons.desktop_windows, l10n.sessions, '/settings/sessions', isDark),
            _buildListTile(context, Icons.key, l10n.authorizedApps, '/settings/apps', isDark),

            const SizedBox(height: 24),

            // Preferences Group
            _buildSectionTitle('Preferences', isDark),
            _buildListTile(context, Icons.notifications, l10n.notifications, '/settings/notifications', isDark),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF615dfa)),
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: ref.watch(localeProvider).languageCode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(localeProvider.notifier).setLocale(val);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Gamification Group
            _buildSectionTitle('Gamification', isDark),
            _buildListTile(context, Icons.emoji_events, l10n.badges, '/settings/badges', isDark),
            _buildListTile(context, Icons.history, l10n.pointsHistory, '/settings/history', isDark),

            const SizedBox(height: 24),

            // Premium Group
            _buildSectionTitle('Premium', isDark),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFF615dfa)),
              title: const Text('Billing & Subscriptions'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                final baseUrl = dotenv.env['BASE_URL']?.replaceAll(RegExp(r'/api$'), '') ?? 'https://myads.example.com';
                _launchUrl('$baseUrl/settings/billing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Color(0xFF615dfa)),
              title: const Text('Monetization / Ads'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                final baseUrl = dotenv.env['BASE_URL']?.replaceAll(RegExp(r'/api$'), '') ?? 'https://myads.example.com';
                _launchUrl('$baseUrl/ads');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String route, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF615dfa)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
