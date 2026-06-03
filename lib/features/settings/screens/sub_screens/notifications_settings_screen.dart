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
    'email_mentions': true,
    'email_messages': true,
    'email_follows': true,
    'email_comments': true,
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
        final data = res.data;
        _prefs = {
          'email_mentions': data['email_mentions'] == 1,
          'email_messages': data['email_messages'] == 1,
          'email_follows': data['email_follows'] == 1,
          'email_comments': data['email_comments'] == 1,
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
        'email_mentions': _prefs['email_mentions']! ? 1 : 0,
        'email_messages': _prefs['email_messages']! ? 1 : 0,
        'email_follows': _prefs['email_follows']! ? 1 : 0,
        'email_comments': _prefs['email_comments']! ? 1 : 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Email Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('New mentions'),
                  value: _prefs['email_mentions']!,
                  onChanged: (val) => setState(() => _prefs['email_mentions'] = val),
                  activeThumbColor: const Color(0xFF615dfa),
                ),
                SwitchListTile(
                  title: const Text('New direct messages'),
                  value: _prefs['email_messages']!,
                  onChanged: (val) => setState(() => _prefs['email_messages'] = val),
                  activeThumbColor: const Color(0xFF615dfa),
                ),
                SwitchListTile(
                  title: const Text('New followers'),
                  value: _prefs['email_follows']!,
                  onChanged: (val) => setState(() => _prefs['email_follows'] = val),
                  activeThumbColor: const Color(0xFF615dfa),
                ),
                SwitchListTile(
                  title: const Text('New comments'),
                  value: _prefs['email_comments']!,
                  onChanged: (val) => setState(() => _prefs['email_comments'] = val),
                  activeThumbColor: const Color(0xFF615dfa),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF615dfa),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}
