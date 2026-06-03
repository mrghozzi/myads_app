import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/hexagon_avatar.dart';

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final response = await ApiClient.instance.get('/messages');
      if (mounted) {
        setState(() {
          _conversations = response.data['conversations'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messages),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final partner = conv['user'];
                    final lastMessage = conv['last_message'] ?? {};
                    final unreadCount = conv['unread_count'] ?? 0;
                    final isUnread = unreadCount > 0;

                    return ListTile(
                      tileColor: isUnread 
                          ? (isDark ? const Color(0xFF615dfa).withValues(alpha: 0.1) : const Color(0xFF615dfa).withValues(alpha: 0.05))
                          : null,
                      leading: HexagonAvatar(
                        avatarUrl: partner['img'] ?? '',
                        size: 48,
                        isOnline: partner['online'] ?? false,
                        isVerified: partner['verified'] ?? false,
                      ),
                      title: Text(
                        partner['name'] ?? partner['username'] ?? 'Unknown',
                        style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(
                        lastMessage['text'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF615dfa),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        final routeKey = conv['route_key'] ?? partner['username'] ?? '';
                        context.push('/messages/$routeKey').then((_) => _fetchConversations());
                      },
                    );
                  },
                ),
    );
  }
}
