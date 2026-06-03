import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class SocialSettingsScreen extends ConsumerStatefulWidget {
  const SocialSettingsScreen({super.key});

  @override
  ConsumerState<SocialSettingsScreen> createState() => _SocialSettingsScreenState();
}

class _SocialSettingsScreenState extends ConsumerState<SocialSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  final List<String> _platforms = ['facebook', 'twitter', 'instagram', 'linkedin', 'youtube', 'tiktok', 'github', 'discord', 'telegram'];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var p in _platforms) {
      _controllers[p] = TextEditingController();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/social');
      if (res.data != null && res.data['socials'] != null) {
        final socials = res.data['socials'] as List;
        for (var s in socials) {
          if (_controllers.containsKey(s['platform'])) {
            _controllers[s['platform']]!.text = s['url'];
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final data = <String, String>{};
    for (var p in _platforms) {
      if (_controllers[p]!.text.isNotEmpty) {
        data[p] = _controllers[p]!.text;
      }
    }
    try {
      await ApiClient.instance.post('/settings/social', data: {'socials': data});
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
      appBar: AppBar(title: Text(l10n.socialLinks)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._platforms.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _controllers[p],
                    decoration: InputDecoration(labelText: p.toUpperCase(), border: const OutlineInputBorder()),
                  ),
                )),
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
