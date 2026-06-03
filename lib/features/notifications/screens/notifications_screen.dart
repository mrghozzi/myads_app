import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/safe_url_launcher.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      if (mounted) {
        setState(() {
          _notifications = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.post('/notifications/mark-all-read');
      setState(() {
        for (var n in _notifications) {
          n['is_unread'] = false;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiClient.instance.post('/notifications/$id/mark-read');
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['is_unread'] = false;
        }
      });
    } catch (_) {}
  }

  IconData _getIconData(String iconName) {
    if (iconName.contains('heart') || iconName.contains('like')) return Icons.favorite;
    if (iconName.contains('comment')) return Icons.comment;
    if (iconName.contains('user') || iconName.contains('follow')) return Icons.person_add;
    return Icons.notifications;
  }

  void _handleTap(Map<String, dynamic> notif) async {
    if (notif['is_unread'] == true) {
      _markAsRead(notif['id']);
    }
    
    final targetUrl = notif['target_url'] as String?;
    if (targetUrl != null && targetUrl.isNotEmpty) {
      if (targetUrl.startsWith('http')) {
        // Security: Validate URL scheme before launching
        SafeUrlLauncher.launch(targetUrl);
      } else {
        context.push(targetUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.markAllRead,
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isUnread = notif['is_unread'] == true;

                    return ListTile(
                      tileColor: isUnread 
                          ? (isDark ? const Color(0xFF615dfa).withValues(alpha: 0.1) : const Color(0xFF615dfa).withValues(alpha: 0.05))
                          : null,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF23d2e2).withValues(alpha: 0.2),
                        child: Icon(
                          _getIconData(notif['icon'] ?? 'bell'),
                          color: const Color(0xFF23d2e2),
                        ),
                      ),
                      title: Text(
                        notif['text'] ?? '',
                        style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: isUnread
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF615dfa),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => _handleTap(notif),
                    );
                  },
                ),
    );
  }
}
