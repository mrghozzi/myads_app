import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class AppsSettingsScreen extends ConsumerStatefulWidget {
  const AppsSettingsScreen({super.key});

  @override
  ConsumerState<AppsSettingsScreen> createState() => _AppsSettingsScreenState();
}

class _AppsSettingsScreenState extends ConsumerState<AppsSettingsScreen> {
  bool _isLoading = true;
  List<dynamic> _apps = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/apps');
      if (res.data != null) {
        _apps = res.data['apps'] ?? [];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revoke(String id) async {
    try {
      await ApiClient.instance.post('/settings/apps/$id/revoke');
      setState(() {
        _apps.removeWhere((a) => a['id'] == id);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App revoked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authorizedApps)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? const Center(child: Text('No authorized apps found'))
              : ListView.builder(
                  itemCount: _apps.length,
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    return ListTile(
                      leading: const Icon(Icons.api),
                      title: Text(app['name'] ?? 'Unknown App'),
                      subtitle: Text('Authorized on ${app['created_at']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _revoke(app['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
