import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:myads_app/l10n/app_localizations.dart';

class SessionsSettingsScreen extends ConsumerStatefulWidget {
  const SessionsSettingsScreen({super.key});

  @override
  ConsumerState<SessionsSettingsScreen> createState() => _SessionsSettingsScreenState();
}

class _SessionsSettingsScreenState extends ConsumerState<SessionsSettingsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  List<dynamic> _sanctumTokens = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/sessions');
      if (res.data != null) {
        setState(() {
          _sessions = res.data['sessions'] ?? [];
          _sanctumTokens = res.data['sanctum_tokens'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeSession(int id) async {
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

  Future<void> _revokeToken(int id) async {
    try {
      await ApiClient.instance.post('/settings/tokens/$id/revoke');
      setState(() {
        _sanctumTokens.removeWhere((t) => t['id'] == id);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device session revoked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessions),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.phone_android), text: 'API Devices'),
            Tab(icon: Icon(Icons.web), text: 'Web Sessions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Sanctum Tokens Tab
                _sanctumTokens.isEmpty
                    ? const Center(child: Text('No active device API tokens found'))
                    : ListView.builder(
                        itemCount: _sanctumTokens.length,
                        itemBuilder: (context, index) {
                          final token = _sanctumTokens[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF615DFA),
                                child: Icon(Icons.smartphone, color: Colors.white, size: 20),
                              ),
                              title: Text(token['name'] ?? 'Device Token', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Last used: ${token['last_used_at'] ?? 'Recently'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _revokeToken(token['id']),
                              ),
                            ),
                          );
                        },
                      ),
                // Web Sessions Tab
                _sessions.isEmpty
                    ? const Center(child: Text('No active web sessions found'))
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Icon(Icons.devices, color: Colors.white, size: 20),
                              ),
                              title: Text(session['device'] ?? 'Unknown Browser', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${session['ip_address'] ?? ''} - ${session['last_activity'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _revokeSession(session['id']),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
