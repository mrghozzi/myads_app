import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class BadgesSettingsScreen extends ConsumerStatefulWidget {
  const BadgesSettingsScreen({super.key});

  @override
  ConsumerState<BadgesSettingsScreen> createState() => _BadgesSettingsScreenState();
}

class _BadgesSettingsScreenState extends ConsumerState<BadgesSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _badges = [];
  Set<int> _selectedBadges = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/badges');
      if (res.data != null) {
        _badges = res.data['badges'] ?? [];
        _selectedBadges = (_badges.where((b) => b['is_shown'] == true).map((b) => b['id'] as int)).toSet();
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
      await ApiClient.instance.post('/settings/badges', data: {
        'showcase': _selectedBadges.toList(),
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
      appBar: AppBar(title: Text(l10n.badges)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _badges.isEmpty
              ? const Center(child: Text('No badges earned yet'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _badges.length,
                        itemBuilder: (context, index) {
                          final badge = _badges[index];
                          final id = badge['id'] as int;
                          final isSelected = _selectedBadges.contains(id);

                          return CheckboxListTile(
                            title: Text(badge['name'] ?? ''),
                            subtitle: Text(badge['description'] ?? ''),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedBadges.add(id);
                                } else {
                                  _selectedBadges.remove(id);
                                }
                              });
                            },
                            activeColor: const Color(0xFF615dfa),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF615dfa),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Showcase', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
