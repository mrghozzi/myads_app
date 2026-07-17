import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/services/secure_storage_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'User not authenticated.';
        _isLoading = false;
      });
      return;
    }

    final baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '') ?? 'http://10.0.2.2:8000';
    final uri = Uri.parse('$baseUrl/billing');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Failed to load: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Mobile-App': 'true', // Optional: could let the web app know it's rendered inside the mobile app
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Subscriptions'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : Stack(
              children: [
                if (!_isLoading && _errorMessage.isEmpty)
                  WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
