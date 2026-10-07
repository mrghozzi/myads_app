import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'orders_provider.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Marketplace'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (orders) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildDisclaimerBanner(isDark);
              }
              final order = orders[index - 1] as Map<String, dynamic>;
              return _buildOrderCard(context, order, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use the website to post a new request.')));
        },
        backgroundColor: const Color(0xFF615dfa),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF615dfa).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF615dfa).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF615dfa), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إخلاء مسؤولية / Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF615dfa)),
                ),
                const SizedBox(height: 4),
                Text(
                  'الموقع يوفر منصة لربط الأطراف والتواصل المباشر. إدارة الموقع تخلي مسؤوليتها القانونية والمالية تماماً عن أي صفقات، وكل عضو مسؤول مسؤولية كاملة عن صفقاته والتأكد من موثوقية الطرف الآخر.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, bool isDark) {
    final buyer = (order['buyer'] as Map<String, dynamic>?) ?? (order['user'] as Map<String, dynamic>?) ?? {};
    final buyerName = buyer['name'] ?? buyer['username'] ?? 'Unknown';
    final buyerAvatar = buyer['avatar'];
    final hasAttachment = order['has_attachment'] == true || order['attachment_name'] != null;
    final isRevision = order['is_revision_requested'] == true;
    final status = (order['workflow_status'] ?? 'open').toString();

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF222630) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/orders/${order['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['title'] ?? 'Untitled Request',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order['budget'] ?? order['budget_min'] ?? 0} PTS',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF615dfa).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF615dfa)),
                    ),
                  ),
                  if (hasAttachment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 12, color: Colors.blue),
                          SizedBox(width: 2),
                          Text('Attachment', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  if (isRevision)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 12, color: Colors.orange),
                          SizedBox(width: 2),
                          Text('Revision', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['description'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: buyerAvatar != null && buyerAvatar.toString().isNotEmpty ? NetworkImage(buyerAvatar.toString()) : null,
                    child: buyerAvatar == null ? const Icon(Icons.person, size: 12) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(buyerName.toString(), style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text('Offers: ${order['offers_count'] ?? 0}', style: const TextStyle(color: Color(0xFF615dfa), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
