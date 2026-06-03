import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  int _visibility = 0;
  int _dm = 0;
  int _mention = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/privacy');
      if (res.data != null) {
        _visibility = res.data['visibility'] ?? 0;
        _dm = res.data['dm'] ?? 0;
        _mention = res.data['mention'] ?? 0;
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
      await ApiClient.instance.post('/settings/privacy', data: {
        'visibility': _visibility,
        'dm': _dm,
        'mention': _mention,
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
      appBar: AppBar(title: Text(l10n.privacy)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _visibility,
                  decoration: const InputDecoration(labelText: 'Profile Visibility', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Public')),
                    DropdownMenuItem(value: 1, child: Text('Members Only')),
                    DropdownMenuItem(value: 2, child: Text('Followers Only')),
                    DropdownMenuItem(value: 3, child: Text('Private')),
                  ],
                  onChanged: (v) => setState(() => _visibility = v ?? 0),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _dm,
                  decoration: const InputDecoration(labelText: 'Who can message me', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Anyone')),
                    DropdownMenuItem(value: 1, child: Text('Followers Only')),
                    DropdownMenuItem(value: 2, child: Text('Nobody')),
                  ],
                  onChanged: (v) => setState(() => _dm = v ?? 0),
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
