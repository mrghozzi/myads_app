import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/feed_provider.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context, ref),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Clips'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF615DFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: 'Post',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF615DFA),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/clips')) return 1;
    if (location.startsWith('/explore')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    if (index == 0) {
      final int currentIdx = _calculateSelectedIndex(context);
      if (currentIdx == 0) {
        // Increment the state to signal the HomeScreen to scroll to top
        ref.read(homeScrollToTopProvider.notifier).increment();
        return;
      }
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/clips');
        break;
      case 2:
        context.push('/compose');
        break;
      case 3:
        context.go('/explore');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

