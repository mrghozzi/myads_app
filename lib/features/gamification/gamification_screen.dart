import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gamification_provider.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests & Rewards'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: questsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (data) {
          final dailyQuests = data['daily_quests'] ?? [];
          final weeklyQuests = data['weekly_quests'] ?? [];
          final ptsBalance = data['user_pts'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Balance Card
              Card(
                elevation: isDark ? 0 : 2,
                color: const Color(0xFF615dfa),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text('Your Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('$ptsBalance PTS', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(context, Icons.send, 'Transfer', () => _showTransferModal(context, ref)),
                          _buildActionButton(context, Icons.card_giftcard, 'Vouchers', () => _showVoucherModal(context, ref)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Daily Quests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...dailyQuests.map<Widget>((q) => _buildQuestCard(context, ref, q, isDark)).toList(),
              
              const SizedBox(height: 24),
              const Text('Weekly Quests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...weeklyQuests.map<Widget>((q) => _buildQuestCard(context, ref, q, isDark)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, WidgetRef ref, Map<String, dynamic> quest, bool isDark) {
    final bool isCompleted = quest['completed'] == true;
    final bool isClaimed = quest['claimed'] == true;
    final progress = quest['progress'] ?? 0;
    final goal = quest['goal'] ?? 1;
    final double progressPercent = (progress / goal).clamp(0.0, 1.0);

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF222630) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF615dfa).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Color(0xFF615dfa), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quest['title'] ?? 'Quest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('+${quest['reward']} PTS', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isClaimed)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (isCompleted)
                  ElevatedButton(
                    onPressed: () async {
                      final success = await ref.read(gamificationActionProvider.notifier).claimQuest(quest['id']);
                      if (success) {
                        ref.invalidate(questsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quest claimed!')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF615dfa)),
                    child: const Text('Claim', style: TextStyle(color: Colors.white)),
                  )
                else
                  Text('$progress / $goal', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            if (!isCompleted && !isClaimed) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF615dfa)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showTransferModal(BuildContext context, WidgetRef ref) {
    final userController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Transfer PTS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (userController.text.isEmpty || amountController.text.isEmpty) return;
              final amount = int.tryParse(amountController.text) ?? 0;
              final success = await ref.read(gamificationActionProvider.notifier).transferPts(userController.text, amount);
              if (success && context.mounted) {
                Navigator.pop(context);
                ref.invalidate(questsProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer successful!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF615dfa)),
            child: const Text('Transfer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVoucherModal(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final createAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('PTS Vouchers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Claim a Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Voucher Code'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty) return;
                final success = await ref.read(gamificationActionProvider.notifier).claimVoucher(codeController.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(questsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher claimed!')));
                }
              },
              child: const Text('Claim'),
            ),
            const Divider(height: 32),
            const Text('Create a Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: createAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (createAmountController.text.isEmpty) return;
                final amount = int.tryParse(createAmountController.text) ?? 0;
                final success = await ref.read(gamificationActionProvider.notifier).createVoucher(amount);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(questsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher created! Check your history.')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
