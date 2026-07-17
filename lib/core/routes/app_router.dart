import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/post_details_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../../features/clips/clips_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/posts/composer_screen.dart';
import '../../features/settings/screens/settings_hub_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/messages/screens/messages_list_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/settings/screens/sub_screens/profile_settings_screen.dart';
import '../../features/settings/screens/sub_screens/privacy_settings_screen.dart';
import '../../features/settings/screens/sub_screens/social_settings_screen.dart';
import '../../features/settings/screens/sub_screens/sessions_settings_screen.dart';
import '../../features/settings/screens/sub_screens/apps_settings_screen.dart';
import '../../features/settings/screens/sub_screens/notifications_settings_screen.dart';
import '../../features/settings/screens/sub_screens/badges_settings_screen.dart';
import '../../features/settings/screens/sub_screens/history_settings_screen.dart';
import '../../features/settings/screens/sub_screens/ads_analytics_screen.dart';
import '../../features/forums/forums_screen.dart';
import '../../features/forums/forum_topics_screen.dart';
import '../../features/forums/forum_topic_detail_screen.dart';
import '../../features/store/store_products_screen.dart';
import '../../features/store/store_product_detail_screen.dart';
import '../../features/orders/orders_list_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/gamification/gamification_screen.dart';
import '../../features/billing/billing_screen.dart';
import '../models/status_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/clips',
          builder: (context, state) => const ClipsScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final username = state.uri.queryParameters['username'] ?? 'me';
            return ProfileScreen(username: username);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsHubScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesListScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/social',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SocialSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/sessions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SessionsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/apps',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/badges',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BadgesSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HistorySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/ads-analytics',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdsAnalyticsScreen(),
    ),
    GoRoute(
      path: '/messages/:username',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return ChatScreen(username: username);
      },
    ),
    GoRoute(
      path: '/post',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final status = state.extra as StatusModel;
        return PostDetailsScreen(status: status);
      },
    ),
    GoRoute(
      path: '/user-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.uri.queryParameters['username'] ?? 'me';
        return ProfileScreen(username: username);
      },
    ),
    GoRoute(
      path: '/compose',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ComposerScreen(
          initialStatus: extra?['status'] as StatusModel?,
          initialText: extra?['text'] as String?,
          initialFilePaths: extra?['filePaths'] as List<String>?,
        );
      },
    ),
    GoRoute(
      path: '/forums',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForumsScreen(),
    ),
    GoRoute(
      path: '/forums/categories/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final name = state.extra as String? ?? 'Topics';
        return ForumTopicsScreen(categoryId: id, categoryName: name);
      },
    ),
    GoRoute(
      path: '/forums/topics/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ForumTopicDetailScreen(topicId: id);
      },
    ),
    GoRoute(
      path: '/store/products',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StoreProductsScreen(),
    ),
    GoRoute(
      path: '/store/products/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return StoreProductDetailScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/orders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OrdersListScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return OrderDetailScreen(orderId: id);
      },
    ),
    GoRoute(
      path: '/quests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GamificationScreen(),
    ),
    GoRoute(
      path: '/billing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BillingScreen(),
    ),
  ],
);

