import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class SessionsSettingsScreen extends ConsumerStatefulWidget {
  const SessionsSettingsScreen({super.key});

  @override
  ConsumerState<SessionsSettingsScreen> createState() => _SessionsSettingsScreenState();
}

class _SessionsSettingsScreenState extends ConsumerState<SessionsSettingsScreen> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/sessions');
      if (res.data != null) {
        _sessions = res.data['sessions'] ?? [];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revoke(int id) async {
    try {
      await ApiClient.instance.post('/settings/sessions/$id/revoke');
      setState(() {
        _sessions.removeWhere((s) => s['id'] == id);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session revoked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessions)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No active sessions found'))
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(session['device'] ?? 'Unknown Device'),
                      subtitle: Text('${session['ip_address']} - ${session['last_activity']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _revoke(session['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
