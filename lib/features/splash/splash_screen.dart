import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/network/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    // Security: Read token from encrypted secure storage
    final hasToken = await SecureStorageService.hasToken();

    if (!mounted) return;

    if (!hasToken) {
      context.go('/login');
      return;
    }

    // Security: Validate token is still valid server-side before navigating
    try {
      final response = await ApiClient.instance.get('/settings/account');
      if (!mounted) return;
      if (response.statusCode == 200) {
        context.go('/home');
      } else {
        // Token is invalid or expired — clear and redirect to login
        await SecureStorageService.deleteToken();
        if (mounted) context.go('/login');
      }
    } catch (_) {
      // Network error or 401 — the interceptor will handle 401 cleanup
      // For other errors, still try to proceed if token exists
      if (!mounted) return;
      final stillHasToken = await SecureStorageService.hasToken();
      if (mounted) context.go(stillHasToken ? '/home' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bubble_chart, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
