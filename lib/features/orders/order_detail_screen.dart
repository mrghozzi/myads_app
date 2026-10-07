import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_provider.dart';
import 'orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final currentUserAsync = ref.watch(profileDetailProvider('me'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Order Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (order) {
          final buyer = (order['buyer'] as Map<String, dynamic>?) ?? (order['user'] as Map<String, dynamic>?) ?? {};
          final offers = (order['offers'] as List<dynamic>?) ?? [];
          final contract = order['contract'] as Map<String, dynamic>?;
          final status = (order['workflow_status'] ?? 'open').toString();
          final hasAttachment = order['has_attachment'] == true || order['attachment_name'] != null;
          final isRevision = order['is_revision_requested'] == true || (contract != null && (contract['revision_count'] ?? 0) > 0);

          final currentUser = currentUserAsync.asData?.value;
          final currentUserId = currentUser?.id;
          final currentUsername = currentUser?.username;
          final isClient = (buyer['id'] != null && currentUserId != null && buyer['id'].toString() == currentUserId.toString()) ||
              (buyer['username'] != null && currentUsername != null && buyer['username'].toString() == currentUsername);
          final isProvider = contract != null &&
              currentUserId != null &&
              contract['provider_user_id'] != null &&
              contract['provider_user_id'].toString() == currentUserId.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Platform Disclaimer Banner
                _buildDisclaimerBanner(isDark),

                // 2. Order Header & Title
                _buildHeaderCard(context, order, buyer, status, isDark),
                const SizedBox(height: 16),

                // 3. Workflow Milestone Stepper
                _buildWorkflowStepper(status, contract, isDark),
                const SizedBox(height: 16),

                // 4. Revision Alert Notice
                if (isRevision && (status == 'in_progress' || status == 'open' || status == 'awarded'))
                  _buildRevisionAlert(contract, isDark),

                // 5. Deliverable Download Card (if delivered or completed)
                if (contract != null && (contract['has_delivery_attachment'] == true || contract['delivery_notes'] != null))
                  _buildDeliverableCard(contract, isDark),

                // 6. Project Requirements Attachment Card
                if (hasAttachment)
                  _buildAttachmentCard(order, isDark),

                // 7. Description
                _buildDescriptionCard(order['description'] ?? '', isDark),
                const SizedBox(height: 20),

                // 8. Dynamic Lifecycle Action Buttons
                _buildActionButtons(context, ref, status, isClient, isProvider, orderId, isDark),
                const SizedBox(height: 28),

                // 9. Offers Section
                _buildOffersSection(context, ref, order, offers, isClient, status, isDark),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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
          const Icon(Icons.shield_outlined, color: Color(0xFF615dfa), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إخلاء مسؤولية / Platform Disclaimer',
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

  Widget _buildHeaderCard(BuildContext context, Map<String, dynamic> order, Map<String, dynamic> buyer, String status, bool isDark) {
    final buyerName = buyer['name'] ?? buyer['username'] ?? 'Unknown Client';
    final buyerAvatar = buyer['avatar'];
    final deliveryDays = order['max_delivery_days'] ?? order['delivery_window_days'] ?? 0;
    final budget = order['budget'] ?? order['budget_min'] ?? 0;
    final category = order['category']?.toString();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'open':
        statusColor = Colors.green;
        statusLabel = 'OPEN';
        break;
      case 'awarded':
        statusColor = Colors.blue;
        statusLabel = 'AWARDED';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF615dfa);
        statusLabel = 'IN PROGRESS';
        break;
      case 'delivered':
        statusColor = Colors.deepPurple;
        statusLabel = 'DELIVERED';
        break;
      case 'completed':
        statusColor = Colors.teal;
        statusLabel = 'COMPLETED';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF1B1E26) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order['title'] ?? 'Untitled Request',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$budget PTS',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                if (category != null && category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: buyerAvatar != null && buyerAvatar.toString().isNotEmpty ? NetworkImage(buyerAvatar.toString()) : null,
                  child: buyerAvatar == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(buyerName.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Client / Buyer', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$deliveryDays Days', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStepper(String status, Map<String, dynamic>? contract, bool isDark) {
    int activeStep;
    switch (status) {
      case 'open':
        activeStep = 1;
        break;
      case 'awarded':
        activeStep = 2;
        break;
      case 'in_progress':
        activeStep = 3;
        break;
      case 'delivered':
        activeStep = 4;
        break;
      case 'completed':
        activeStep = 5;
        break;
      default:
        activeStep = 1;
    }

    final steps = [
      {'num': 1, 'label': 'Matching'},
      {'num': 2, 'label': 'Awarded'},
      {'num': 3, 'label': 'In Progress'},
      {'num': 4, 'label': 'Delivered'},
      {'num': 5, 'label': 'Completed'},
    ];

    final isOverdue = contract?['is_overdue'] == true;
    final deadline = contract?['deadline']?.toString();

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF1B1E26) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timeline, color: Color(0xFF615dfa), size: 20),
                    SizedBox(width: 8),
                    Text('Milestone Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                if (deadline != null && deadline.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isOverdue ? Colors.red : Colors.blue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: isOverdue ? Colors.red : Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue ? 'Overdue' : 'Due: ${deadline.split('T').first}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : Colors.blue),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: steps.map((s) {
                final stepNum = s['num'] as int;
                final isDone = activeStep >= stepNum;
                final isCurrent = activeStep == stepNum;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? const Color(0xFF615dfa) : (isDark ? Colors.white12 : Colors.grey[200]),
                          border: isCurrent ? Border.all(color: Colors.amber, width: 2) : null,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text('$stepNum', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? const Color(0xFF615dfa) : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionAlert(Map<String, dynamic>? contract, bool isDark) {
    final note = contract?['revision_note']?.toString();
    final count = contract?['revision_count'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.replay_circle_filled, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'طلب تعديل / Revision Requested (Round #$count)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliverableCard(Map<String, dynamic> contract, bool isDark) {
    final fileName = contract['delivery_attachment_name']?.toString();
    final notes = contract['delivery_notes']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'العمل المُسلّم / Deliverable Work',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
              ),
            ],
          ),
          if (fileName != null && fileName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.file_present_outlined, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> order, bool isDark) {
    final fileName = order['attachment_name']?.toString() ?? 'Project Attachment';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملف متطلبات المشروع / Requirements Attachment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description, bool isDark) {
    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF1B1E26) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description & Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              description.isNotEmpty ? description : 'No description provided.',
              style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String status,
    bool isClient,
    bool isProvider,
    int orderId,
    bool isDark,
  ) {
    // 1. Client actions for Delivered status
    if (isClient && status == 'delivered') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteModal(context, ref, orderId),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Accept & Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRevisionModal(context, ref, orderId),
              icon: const Icon(Icons.replay_rounded, color: Colors.orange),
              label: const Text('Request Revision', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // 2. Provider actions for Awarded status
    if (isProvider && status == 'awarded') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final ok = await ref.read(orderActionProvider.notifier).startWork(orderId);
            if (ok && context.mounted) {
              ref.invalidate(orderDetailProvider(orderId));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order started successfully!')));
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text('Start Working on Order', style: TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF615dfa),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // 3. Provider actions for In Progress status
    if (isProvider && status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showDeliverModal(context, ref, orderId),
          icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
          label: const Text('Deliver Completed Work', style: TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // 4. General Open status: Submit Offer button for providers
    if (status == 'open' && !isClient) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showSubmitOfferModal(context, ref, orderId),
          icon: const Icon(Icons.local_offer_outlined, color: Colors.white),
          label: const Text('Submit Offer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF615dfa),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOffersSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> order,
    List<dynamic> offers,
    bool isClient,
    String status,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Offers & Proposals (${offers.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (status != 'open')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Closed for new offers', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (offers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E26) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No offers submitted yet.', style: TextStyle(color: Colors.grey)),
          ),
        ...offers.map<Widget>((offerItem) {
          final offer = offerItem as Map<String, dynamic>;
          final provider = (offer['provider'] as Map<String, dynamic>?) ?? (offer['user'] as Map<String, dynamic>?) ?? {};
          final providerName = provider['name'] ?? provider['username'] ?? 'Unknown Provider';
          final providerAvatar = provider['avatar'];
          final isAwarded = offer['status'] == 'awarded' || (order['awarded_offer_id'] != null && order['awarded_offer_id'].toString() == offer['id'].toString());
          final canAward = isClient && status == 'open' && offer['status'] != 'withdrawn';

          return Card(
            color: isDark ? const Color(0xFF1B1E26) : Colors.white,
            elevation: isDark ? 0 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isAwarded ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: providerAvatar != null && providerAvatar.toString().isNotEmpty ? NetworkImage(providerAvatar.toString()) : null,
                        child: providerAvatar == null ? const Icon(Icons.person, size: 16) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    providerName.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAwarded) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('AWARDED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text('Delivery in ${offer['delivery_days'] ?? 0} days', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        '${offer['price']} PTS',
                        style: const TextStyle(color: Color(0xFF615dfa), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    offer['txt'] ?? offer['message'] ?? '',
                    style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                  ),
                  if (offer['client_rating'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (starIdx) {
                          final rating = int.tryParse(offer['client_rating'].toString()) ?? 0;
                          return Icon(
                            starIdx < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        if (offer['client_review'] != null && offer['client_review'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${offer['client_review']}"',
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (canAward) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Award Offer'),
                              content: Text('Are you sure you want to award this contract to $providerName?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Award')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final ok = await ref.read(orderActionProvider.notifier).awardOffer(order['id'] as int, offer['id'] as int);
                            if (ok && context.mounted) {
                              ref.invalidate(orderDetailProvider(order['id'] as int));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer awarded successfully!')));
                            }
                          }
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Award Offer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
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

  void _showRevisionModal(BuildContext context, WidgetRef ref, int orderId) {
    final noteController = TextEditingController();

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
              const Text('Request Revision', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 8),
              const Text('Explain clearly what changes and revisions are required from the provider.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Revision Details / ملاحظات التعديل', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (noteController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter revision details')));
                    return;
                  }
                  final success = await ref.read(orderActionProvider.notifier).requestRevision(orderId, noteController.text.trim());
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(orderDetailProvider(orderId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revision requested successfully!')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Send Revision Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeliverModal(BuildContext context, WidgetRef ref, int orderId) {
    final noteController = TextEditingController();

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
              const Text('Deliver Completed Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              const Text('Provide any delivery notes or download instructions for the client.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Delivery Notes / ملاحظات التسليم', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref.read(orderActionProvider.notifier).deliverWork(orderId, deliveryNote: noteController.text.trim());
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(orderDetailProvider(orderId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work delivered successfully!')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showCompleteModal(BuildContext context, WidgetRef ref, int orderId) {
    final reviewController = TextEditingController();
    int rating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
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
                  const Text('Accept & Complete Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  const Text('Rate your experience with the service provider and provide your review.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(star <= rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                        onPressed: () => setStateModal(() => rating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Feedback Review (Optional) / تقييم الخدمة', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await ref.read(orderActionProvider.notifier).completeOrder(
                            orderId,
                            rating: rating,
                            review: reviewController.text.trim().isNotEmpty ? reviewController.text.trim() : null,
                          );
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(orderDetailProvider(orderId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order completed and reviewed!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Complete Order & Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
