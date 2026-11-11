import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, bool> _prefs = {
    // Email preferences
    'email_mentions': true,
    'email_messages': true,
    'email_follows': true,
    'email_comments': true,
    // Push preferences
    'push_mentions': true,
    'push_messages': true,
    'push_follows': true,
    'push_comments': true,
    'push_reactions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/notifications');
      if (res.data != null) {
        bool isTrue(dynamic val) => val == true || val == 1 || val == '1';
        final data = res.data is Map ? (res.data as Map) : {};
        final settings = (data['settings'] is Map) ? (data['settings'] as Map) : {};

        _prefs = {
          'email_mentions': isTrue(data['email_mentions'] ?? settings['email_mention'] ?? true),
          'email_messages': isTrue(data['email_messages'] ?? settings['email_new_message'] ?? true),
          'email_follows': isTrue(data['email_follows'] ?? settings['email_new_follower'] ?? true),
          'email_comments': isTrue(data['email_comments'] ?? settings['email_new_comment'] ?? true),
          'push_mentions': isTrue(data['push_mentions'] ?? settings['push_mention'] ?? true),
          'push_messages': isTrue(data['push_messages'] ?? settings['push_new_message'] ?? true),
          'push_follows': isTrue(data['push_follows'] ?? settings['push_new_follower'] ?? true),
          'push_comments': isTrue(data['push_comments'] ?? settings['push_new_comment'] ?? true),
          'push_reactions': isTrue(data['push_reactions'] ?? settings['push_reaction'] ?? true),
        };
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.post('/settings/notifications', data: {
        // Email
        'email_mentions': _prefs['email_mentions']! ? 1 : 0,
        'email_messages': _prefs['email_messages']! ? 1 : 0,
        'email_follows': _prefs['email_follows']! ? 1 : 0,
        'email_comments': _prefs['email_comments']! ? 1 : 0,
        // Push
        'push_mentions': _prefs['push_mentions']! ? 1 : 0,
        'push_messages': _prefs['push_messages']! ? 1 : 0,
        'push_follows': _prefs['push_follows']! ? 1 : 0,
        'push_comments': _prefs['push_comments']! ? 1 : 0,
        'push_reactions': _prefs['push_reactions']! ? 1 : 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = const Color(0xFF615DFA);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Push Notifications Section
                Row(
                  children: [
                    Icon(Icons.phone_android_rounded, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'إشعارات الهاتف (Push Notifications)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('الإشارات والمنشن (@mentions)'),
                  value: _prefs['push_mentions']!,
                  onChanged: (val) => setState(() => _prefs['push_mentions'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('الرسائل الخاصة المباشرة'),
                  value: _prefs['push_messages']!,
                  onChanged: (val) => setState(() => _prefs['push_messages'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('المتابعون الجدد'),
                  value: _prefs['push_follows']!,
                  onChanged: (val) => setState(() => _prefs['push_follows'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('التعليقات على منشوراتك'),
                  value: _prefs['push_comments']!,
                  onChanged: (val) => setState(() => _prefs['push_comments'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('التفاعلات والإعجابات'),
                  value: _prefs['push_reactions']!,
                  onChanged: (val) => setState(() => _prefs['push_reactions'] = val),
                  activeThumbColor: primaryColor,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Email Notifications Section
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'إشعارات البريد الإلكتروني (Email)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('الإشارات في التعليقات والمنشورات'),
                  value: _prefs['email_mentions']!,
                  onChanged: (val) => setState(() => _prefs['email_mentions'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('تنبيهات الرسائل الخاصة'),
                  value: _prefs['email_messages']!,
                  onChanged: (val) => setState(() => _prefs['email_messages'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('تنبيه بالمتابعين الجدد'),
                  value: _prefs['email_follows']!,
                  onChanged: (val) => setState(() => _prefs['email_follows'] = val),
                  activeThumbColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('تنبيه بالتعليقات الجديدة'),
                  value: _prefs['email_comments']!,
                  onChanged: (val) => setState(() => _prefs['email_comments'] = val),
                  activeThumbColor: primaryColor,
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
