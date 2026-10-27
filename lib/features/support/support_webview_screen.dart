import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/safe_url_launcher.dart';

class SupportWebviewScreen extends StatefulWidget {
  final String title;
  final String path;

  const SupportWebviewScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<SupportWebviewScreen> createState() => _SupportWebviewScreenState();
}

class _SupportWebviewScreenState extends State<SupportWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  String _targetUrl = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final token = await SecureStorageService.getToken();
    final baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '') ?? 'http://10.0.2.2:8000';
    
    // Normalize path
    final cleanPath = widget.path.startsWith('/') ? widget.path : '/${widget.path}';
    _targetUrl = '$baseUrl$cleanPath';
    final uri = Uri.parse(_targetUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = '';
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
      );

    final headers = <String, String>{
      'X-Mobile-App': 'true',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _controller.loadRequest(uri, headers: headers);
  }

  void _openInExternalBrowser() {
    if (_targetUrl.isNotEmpty) {
      SafeUrlLauncher.launch(_targetUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E222B) : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                _controller.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Open in browser',
              onPressed: _openInExternalBrowser,
            ),
          ],
        ),
        body: _errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _initWebView,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _openInExternalBrowser,
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Open in external browser'),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const LinearProgressIndicator(
                      color: Color(0xFF615DFA),
                      backgroundColor: Colors.transparent,
                    ),
                ],
              ),
      ),
    );
  }
}
