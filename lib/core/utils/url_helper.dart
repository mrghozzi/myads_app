import 'package:flutter_dotenv/flutter_dotenv.dart';

class UrlHelper {
  /// Normalizes a URL received from the Laravel backend, converting relative paths
  /// and rewriting 'localhost' to the correct network host of the current device.
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;

    // Get BASE_URL from environment variables (e.g. http://192.168.1.163/myads/api)
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (baseUrl.isEmpty) return url;

    // Extract the site base URL by removing '/api' or '/api/'
    String siteBaseUrl = baseUrl;
    if (siteBaseUrl.endsWith('/api')) {
      siteBaseUrl = siteBaseUrl.substring(0, siteBaseUrl.length - 4);
    } else if (siteBaseUrl.endsWith('/api/')) {
      siteBaseUrl = siteBaseUrl.substring(0, siteBaseUrl.length - 5);
    }

    // Ensure siteBaseUrl doesn't end with a slash for consistent replacements
    if (siteBaseUrl.endsWith('/')) {
      siteBaseUrl = siteBaseUrl.substring(0, siteBaseUrl.length - 1);
    }

    // Case 1: URL is an absolute localhost URL from backend APP_URL configuration
    if (url.startsWith('http://localhost/myads')) {
      return url.replaceFirst('http://localhost/myads', siteBaseUrl);
    }
    
    // Case 2: URL has localhost but maybe in a different path format
    if (url.startsWith('http://localhost') && !siteBaseUrl.contains('localhost')) {
      // E.g. replace http://localhost with http://192.168.1.163
      // We extract host prefix of siteBaseUrl (e.g., http://192.168.1.163/myads -> http://192.168.1.163)
      final uri = Uri.parse(siteBaseUrl);
      final hostPrefix = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      return url.replaceFirst('http://localhost', hostPrefix);
    }

    // Case 3: URL is relative (e.g., "upload/avatar.png")
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = siteBaseUrl.endsWith('/') ? siteBaseUrl : '$siteBaseUrl/';
      final relative = url.startsWith('/') ? url.substring(1) : url;
      return Uri.encodeFull('$base$relative');
    }

    return Uri.encodeFull(url);
  }
}
