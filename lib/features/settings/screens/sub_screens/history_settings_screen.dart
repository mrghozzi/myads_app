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
  String _selectedFilter = 'all';
  List<dynamic> _transactions = [];

  static const List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'All', 'icon': Icons.layers_outlined},
    {'id': 'credits', 'label': 'Earned (+)', 'icon': Icons.arrow_downward_rounded},
    {'id': 'debits', 'label': 'Spent (-)', 'icon': Icons.arrow_upward_rounded},
    {'id': 'transfers', 'label': 'Transfers', 'icon': Icons.swap_horiz_rounded},
    {'id': 'ads', 'label': 'Ads', 'icon': Icons.campaign_outlined},
    {'id': 'rewards', 'label': 'Rewards', 'icon': Icons.card_giftcard_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance.get(
        '/settings/history',
        queryParameters: _selectedFilter != 'all' ? {'filter': _selectedFilter} : null,
      );
      if (res.data != null) {
        final list = res.data['data'] ?? res.data['history'] ?? (res.data is List ? res.data : []);
        _transactions = list is List ? list : [];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterSelected(String filterId) {
    if (_selectedFilter == filterId) return;
    setState(() {
      _selectedFilter = filterId;
      _isLoading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Ledger & Statement'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        f['icon'] as IconData,
                        size: 16,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                      label: Text(f['label'] as String),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      selectedColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                        ),
                      ),
                      onSelected: (_) => _onFilterSelected(f['id'] as String),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Transaction List with Refresh Indicator
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 64, color: theme.disabledColor),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.disabledColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Transactions matching this filter will appear here.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _transactions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            final amount = (tx['amount'] is num)
                                ? (tx['amount'] as num).toDouble()
                                : double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                            final isPositive = amount >= 0;
                            final balanceAfter = tx['balance_after'];
                            final description = tx['description'] ?? tx['description_key'] ?? 'Transaction';
                            final type = tx['type']?.toString().toUpperCase().replaceAll('_', ' ');

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isPositive
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                child: Icon(
                                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isPositive ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                description,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (tx['created_at'] != null && tx['created_at'].toString().isNotEmpty) ...[
                                        Icon(Icons.calendar_today_outlined, size: 11, color: theme.hintColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          tx['created_at'].toString(),
                                          style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (type != null && type.isNotEmpty && type != 'REWARD' && type != 'LEGACY')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (balanceAfter != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 12,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Running Balance: $balanceAfter PTS',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Text(
                                '${isPositive ? '+' : ''}${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} PTS',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
