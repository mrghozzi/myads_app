import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Security utility for validating and safely launching URLs.
///
/// Prevents launching dangerous URI schemes (file://, intent://, content://)
/// that could be injected via compromised server data.
class SafeUrlLauncher {
  /// Allowed URI schemes for external launching
  static const _allowedSchemes = {'http', 'https', 'mailto', 'tel'};

  /// Safely launches a URL after validating its scheme.
  /// Returns true if launched successfully, false otherwise.
  static Future<bool> launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (kDebugMode) debugPrint('SafeUrlLauncher: Invalid URL: $url');
      return false;
    }

    if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      if (kDebugMode) debugPrint('SafeUrlLauncher: Blocked unsafe scheme: ${uri.scheme}');
      return false;
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SafeUrlLauncher: Error launching $url: $e');
    }
    return false;
  }

  /// Validate a URL without launching it.
  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && _allowedSchemes.contains(uri.scheme.toLowerCase());
  }
}
