import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/network/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      final response = await ApiClient.instance.get('/user');
      if (!mounted) return;
      if (response.statusCode == 200) {
        context.go('/home');
      } else {
        // Token is invalid or expired — clear and redirect to login
        await SecureStorageService.deleteToken();
        if (mounted) context.go('/login');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await SecureStorageService.deleteToken();
        context.go('/login');
      } else {
        final stillHasToken = await SecureStorageService.hasToken();
        context.go(stillHasToken ? '/home' : '/login');
      }
    } catch (_) {
      // Network error 
      if (!mounted) return;
      final stillHasToken = await SecureStorageService.hasToken();
      context.go(stillHasToken ? '/home' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo_w.png',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
