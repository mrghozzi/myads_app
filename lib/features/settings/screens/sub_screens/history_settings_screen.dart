import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class HistorySettingsScreen extends ConsumerStatefulWidget {
  const HistorySettingsScreen({super.key});

  @override
  ConsumerState<HistorySettingsScreen> createState() => _HistorySettingsScreenState();
}

class _HistorySettingsScreenState extends ConsumerState<HistorySettingsScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get('/settings/history');
      if (res.data != null) {
        _transactions = res.data['history'] ?? [];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Points Ledger')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No point transactions found'))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final amount = tx['amount'] ?? 0;
                    final isPositive = amount >= 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPositive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        child: Icon(
                          isPositive ? Icons.add : Icons.remove,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx['description'] ?? 'Transaction'),
                      subtitle: Text(tx['created_at'] ?? ''),
                      trailing: Text(
                        '${isPositive ? '+' : ''}$amount PTS',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
