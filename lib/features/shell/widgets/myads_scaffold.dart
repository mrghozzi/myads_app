import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/profile_provider.dart';
import '../../../core/widgets/hexagon_avatar.dart';

class MyAdsScaffold extends ConsumerWidget {
  final Widget body;
  final String title;

  const MyAdsScaffold({
    super.key,
    required this.body,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileDetailProvider('me'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () => context.push('/messages'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: userAsync.when(
                data: (user) => GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: HexagonAvatar(
                    avatarUrl: user.avatar,
                    size: 32,
                    isVerified: user.verified,
                    isOnline: user.online,
                    profileBadgeColor: user.profileBadgeColor,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, stack) => GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF615DFA),
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}

