import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (order) {
          final buyer = order['buyer'] ?? {};
          final offers = order['offers'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order['title'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${order['budget'] ?? 0} PTS',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: buyer['avatar'] != null ? NetworkImage(buyer['avatar']) : null,
                      child: buyer['avatar'] == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 8),
                    Text(buyer['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('Delivery: ${order['max_delivery_days'] ?? 0} Days', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(order['description'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 32),
                
                // Submit Offer Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showSubmitOfferModal(context, ref, orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF615dfa),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Offer', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),

                // Offers List
                Text('Offers (${offers.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (offers.isEmpty)
                  const Text('No offers yet.', style: TextStyle(color: Colors.grey)),
                ...offers.map<Widget>((offer) {
                  final provider = offer['provider'] ?? {};
                  return Card(
                    color: isDark ? const Color(0xFF1B1E26) : Colors.grey[50],
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: provider['avatar'] != null ? NetworkImage(provider['avatar']) : null,
                                child: provider['avatar'] == null ? const Icon(Icons.person, size: 12) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(provider['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Spacer(),
                              Text('${offer['price']} PTS', style: const TextStyle(color: Color(0xFF615dfa), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(offer['txt'] ?? '', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('Delivery in ${offer['delivery_days']} days', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSubmitOfferModal(BuildContext context, WidgetRef ref, int orderId) {
    final textController = TextEditingController();
    final priceController = TextEditingController();
    final deliveryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Submit Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Cover Letter / Proposal', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (PTS)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: deliveryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Delivery (Days)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (textController.text.isEmpty || priceController.text.isEmpty || deliveryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }
                  final price = int.tryParse(priceController.text) ?? 0;
                  final delivery = int.tryParse(deliveryController.text) ?? 0;
                  
                  final success = await ref.read(orderActionProvider.notifier).submitOffer(orderId, textController.text, price, delivery);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(orderDetailProvider(orderId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer submitted successfully!')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF615dfa),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
