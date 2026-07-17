import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final adsAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get('/ads/stats');
  if (response.data['success'] == true) {
    return response.data['data'];
  }
  throw Exception('Failed to load stats');
});

class AdsAnalyticsScreen extends ConsumerWidget {
  const AdsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adsAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Analytics'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (data) {
          final visits = data['visits'];
          final ads = data['ads'];
          final wallet = data['wallet'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildStatCard('Wallet Balance', '${wallet['pts']} PTS', Icons.account_balance_wallet, Colors.green, isDark),
              const SizedBox(height: 16),
              const Text('Surf-to-Earn (Visits)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Today', '${visits['today']}', Icons.today, Colors.blue, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Total', '${visits['total']}', Icons.assessment, Colors.purple, isDark)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Ads Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Banners', '${ads['banner_impressions']}\nImpressions', Icons.image, Colors.orange, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Smart Ads', '${ads['smart_impressions']}\nImpressions', Icons.language, Colors.teal, isDark)),
                ],
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Note: Creating new campaigns or managing exchanges is currently available only on the website.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, bool isDark) {
    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF222630) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
