import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/safe_url_launcher.dart';

/// Smart text content renderer supporting BBCode, Markdown (.md), HTML, and plain text
/// with full theme awareness, link tapping, RTL detection, and custom styling.
class FormattedContentWidget extends StatelessWidget {
  final String content;
  final double fontSize;
  final int? maxLines;
  final TextStyle? style;
  final bool selectable;

  const FormattedContentWidget({
    super.key,
    required this.content,
    this.fontSize = 15.0,
    this.maxLines,
    this.style,
    this.selectable = true,
  });

  /// Convert BBCode tags to standard Markdown / HTML formatting
  static String convertBbcodeToMarkdown(String text) {
    if (!text.contains('[')) return text;

    String result = text;

    // Run 2 iterations to handle nested BBCode tags cleanly
    for (int i = 0; i < 2; i++) {
      if (!result.contains('[')) break;

      // Bold: [b]text[/b]
      result = result.replaceAllMapped(
        RegExp(r'\[b\](.*?)\[/b\]', caseSensitive: false, dotAll: true),
        (m) => '**${m[1] ?? ''}**',
      );

      // Italic: [i]text[/i]
      result = result.replaceAllMapped(
        RegExp(r'\[i\](.*?)\[/i\]', caseSensitive: false, dotAll: true),
        (m) => '*${m[1] ?? ''}*',
      );

      // Underline: [u]text[/u]
      result = result.replaceAllMapped(
        RegExp(r'\[u\](.*?)\[/u\]', caseSensitive: false, dotAll: true),
        (m) => '<u>${m[1] ?? ''}</u>',
      );

      // Strikethrough: [s]text[/s] or [strike]text[/strike]
      result = result.replaceAllMapped(
        RegExp(r'\[(?:s|strike)\](.*?)\[/(?:s|strike)\]', caseSensitive: false, dotAll: true),
        (m) => '~~${m[1] ?? ''}~~',
      );

      // Links with label: [url=http://example.com]Label[/url]
      result = result.replaceAllMapped(
        RegExp(r'\[url=([^\]]+)\](.*?)\[/url\]', caseSensitive: false, dotAll: true),
        (m) => '[${m[2] ?? ''}](${(m[1] ?? '').trim()})',
      );

      // Plain links: [url]http://example.com[/url]
      result = result.replaceAllMapped(
        RegExp(r'\[url\](.*?)\[/url\]', caseSensitive: false, dotAll: true),
        (m) => '[${m[1] ?? ''}](${(m[1] ?? '').trim()})',
      );

      // Email with label: [email=user@domain.com]Contact[/email]
      result = result.replaceAllMapped(
        RegExp(r'\[email=([^\]]+)\](.*?)\[/email\]', caseSensitive: false, dotAll: true),
        (m) => '[${m[2] ?? ''}](mailto:${(m[1] ?? '').trim()})',
      );

      // Plain Email: [email]user@domain.com[/email]
      result = result.replaceAllMapped(
        RegExp(r'\[email\](.*?)\[/email\]', caseSensitive: false, dotAll: true),
        (m) => '[${m[1] ?? ''}](mailto:${(m[1] ?? '').trim()})',
      );

      // Images: [img]http://example.com/image.jpg[/img]
      result = result.replaceAllMapped(
        RegExp(r'\[img\](.*?)\[/img\]', caseSensitive: false, dotAll: true),
        (m) => '![](${(m[1] ?? '').trim()})',
      );

      // Quote with user: [quote=Username]text[/quote]
      result = result.replaceAllMapped(
        RegExp(r'\[quote=([^\]]+)\](.*?)\[/quote\]', caseSensitive: false, dotAll: true),
        (m) => '> **${m[1] ?? ''}:**\n> ${(m[2] ?? '').replaceAll('\n', '\n> ')}',
      );

      // Simple quote: [quote]text[/quote]
      result = result.replaceAllMapped(
        RegExp(r'\[quote\](.*?)\[/quote\]', caseSensitive: false, dotAll: true),
        (m) => '> ${(m[1] ?? '').replaceAll('\n', '\n> ')}',
      );

      // Code with language: [code=php]code[/code]
      result = result.replaceAllMapped(
        RegExp(r'\[code=([^\]]+)\](.*?)\[/code\]', caseSensitive: false, dotAll: true),
        (m) => '```${m[1] ?? ''}\n${m[2] ?? ''}\n```',
      );

      // Code without language: [code]code[/code]
      result = result.replaceAllMapped(
        RegExp(r'\[code\](.*?)\[/code\]', caseSensitive: false, dotAll: true),
        (m) => '```\n${m[1] ?? ''}\n```',
      );

      // Unordered list: [list] [*]item 1 [*]item 2 [/list]
      result = result.replaceAllMapped(
        RegExp(r'\[list\](.*?)\[/list\]', caseSensitive: false, dotAll: true),
        (m) => (m[1] ?? '').replaceAll(RegExp(r'\[\*\]'), '\n- '),
      );

      // Ordered list: [list=1] [*]item 1 [*]item 2 [/list]
      result = result.replaceAllMapped(
        RegExp(r'\[list=1\](.*?)\[/list\]', caseSensitive: false, dotAll: true),
        (m) {
          int count = 1;
          return (m[1] ?? '').replaceAllMapped(RegExp(r'\[\*\]'), (itemMatch) => '\n${count++}. ');
        },
      );

      // Color: [color=red]text[/color]
      result = result.replaceAllMapped(
        RegExp(r'\[color=([^\]]+)\](.*?)\[/color\]', caseSensitive: false, dotAll: true),
        (m) => '<font color="${m[1] ?? ''}">${m[2] ?? ''}</font>',
      );

      // Center / Left / Right
      result = result.replaceAllMapped(
        RegExp(r'\[(?:center|left|right)\](.*?)\[/(?:center|left|right)\]', caseSensitive: false, dotAll: true),
        (m) => m[1] ?? '',
      );

      // Size tag
      result = result.replaceAllMapped(
        RegExp(r'\[size=([^\]]+)\](.*?)\[/size\]', caseSensitive: false, dotAll: true),
        (m) => m[2] ?? '',
      );

      // YouTube tags: [youtube]v_id[/youtube]
      result = result.replaceAllMapped(
        RegExp(r'\[youtube\](.*?)\[/youtube\]', caseSensitive: false, dotAll: true),
        (m) => '[YouTube Video](https://www.youtube.com/watch?v=${(m[1] ?? '').trim()})',
      );
    }

    return result;
  }

  /// Check if text contains Markdown syntax indicators
  bool _isMarkdown(String text) {
    final mdRegex = RegExp(
      r'(^|\n|\r)(#+ |[*_-]{3,}|[*+-] |\d+\. |```|> )|(\*\*|__|\*|_|~~|`|\[[^\]]+\]\([^)]+\)|!\[[^\]]*\]\([^)]+\))',
      multiLine: true,
    );
    return mdRegex.hasMatch(text);
  }

  /// Check if text contains HTML tags
  bool _isHtml(String text) {
    final htmlRegex = RegExp(
      r'</?(?:p|div|span|h[1-6]|b|i|strong|em|a|ul|ol|li|br|blockquote|code|pre|img|font|u|s)\b[^>]*>',
      caseSensitive: false,
    );
    return htmlRegex.hasMatch(text);
  }

  /// Security: Strip dangerous HTML tags
  static final _dangerousTagPattern = RegExp(
    r'</?(?:script|iframe|object|embed|form|input|textarea|select|button|meta|link|base)\b[^>]*>',
    caseSensitive: false,
  );

  String _sanitizeHtml(String html) {
    return html.replaceAll(_dangerousTagPattern, '');
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Convert HTML tags like <br>, <p> to Markdown equivalents if content has Markdown
  String _normalizeMarkdown(String text) {
    String normalized = text;
    normalized = normalized.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    normalized = normalized.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    normalized = normalized.replaceAll(RegExp(r'<p\b[^>]*>', caseSensitive: false), '');
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    // Step 1: Pre-process BBCode into Markdown/HTML
    final processedContent = convertBbcodeToMarkdown(content);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = style?.color ?? theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white : Colors.black87);
    final textDirection = _isArabic(processedContent) ? TextDirection.rtl : TextDirection.ltr;

    final hasMarkdown = _isMarkdown(processedContent);
    final hasHtml = _isHtml(processedContent);

    Widget child;

    if (hasMarkdown || !hasHtml) {
      // Render as Markdown (handles pure Markdown, converted BBCode, mixed Markdown, and plain text)
      final normalizedData = _normalizeMarkdown(processedContent);

      final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: defaultColor,
        ),
        h1: TextStyle(
          fontSize: fontSize + 6,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h2: TextStyle(
          fontSize: fontSize + 4,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h3: TextStyle(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h4: TextStyle(
          fontSize: fontSize + 1,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        code: TextStyle(
          backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
          fontFamily: 'monospace',
          fontSize: fontSize - 1,
          color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFD84315),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        blockquoteDecoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        a: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        listBullet: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: fontSize,
        ),
      );

      child = MarkdownBody(
        data: normalizedData,
        selectable: selectable,
        styleSheet: styleSheet,
        onTapLink: (text, href, title) {
          if (href != null && href.isNotEmpty) {
            SafeUrlLauncher.launch(href);
          }
        },
      );
    } else {
      // Pure HTML rendering
      final sanitizedData = _sanitizeHtml(processedContent);

      child = Html(
        data: sanitizedData,
        onLinkTap: (url, attributes, element) {
          if (url != null && url.isNotEmpty) {
            SafeUrlLauncher.launch(url);
          }
        },
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(fontSize),
            lineHeight: const LineHeight(1.5),
            color: defaultColor,
          ),
          "a": Style(
            color: theme.colorScheme.primary,
            textDecoration: TextDecoration.underline,
          ),
        },
      );
    }

    if (maxLines != null) {
      child = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: fontSize * 1.5 * maxLines!,
        ),
        child: ClipRect(
          child: child,
        ),
      );
    }

    return Directionality(
      textDirection: textDirection,
      child: child,
    );
  }
}
