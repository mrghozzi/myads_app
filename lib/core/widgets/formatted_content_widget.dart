import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import '../utils/safe_url_launcher.dart';

/// Smart text content renderer supporting BBCode, Markdown (.md), HTML, and plain text
/// with full theme awareness, link tapping, RTL detection, expandable view ("See more" / "See less"),
/// multi-language support, and custom styling.
class FormattedContentWidget extends StatefulWidget {
  final String content;
  final double fontSize;
  final int? maxLines;
  final TextStyle? style;
  final bool selectable;
  final bool isExpandable;
  final int collapsedMaxLines;
  final bool initiallyExpanded;
  final String? seeMoreLabel;
  final String? seeLessLabel;
  final bool showGradientFade;
  final ValueChanged<bool>? onExpandToggled;

  const FormattedContentWidget({
    super.key,
    required this.content,
    this.fontSize = 15.0,
    this.maxLines,
    this.style,
    this.selectable = true,
    this.isExpandable = false,
    this.collapsedMaxLines = 5,
    this.initiallyExpanded = false,
    this.seeMoreLabel,
    this.seeLessLabel,
    this.showGradientFade = true,
    this.onExpandToggled,
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
  static bool isMarkdown(String text) {
    final mdRegex = RegExp(
      r'(^|\n|\r)(#+ |[*_-]{3,}|[*+-] |\d+\. |```|> )|(\*\*|__|\*|_|~~|`|\[[^\]]+\]\([^)]+\)|!\[[^\]]*\]\([^)]+\))',
      multiLine: true,
    );
    return mdRegex.hasMatch(text);
  }

  /// Check if text contains HTML tags
  static bool isHtml(String text) {
    final htmlRegex = RegExp(
      r'</?(?:p|div|span|h[1-6]|b|i|strong|em|a|ul|ol|li|br|blockquote|code|pre|img|font|u|s)\b[^>]*>',
      caseSensitive: false,
    );
    return htmlRegex.hasMatch(text);
  }

  /// Security: Strip dangerous HTML tags
  static final RegExp dangerousTagPattern = RegExp(
    r'</?(?:script|iframe|object|embed|form|input|textarea|select|button|meta|link|base)\b[^>]*>',
    caseSensitive: false,
  );

  static String sanitizeHtml(String html) {
    return html.replaceAll(dangerousTagPattern, '');
  }

  static bool isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Convert HTML tags like <br>, <p> to Markdown equivalents if content has Markdown
  static String normalizeMarkdown(String text) {
    String normalized = text;
    normalized = normalized.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    normalized = normalized.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    normalized = normalized.replaceAll(RegExp(r'<p\b[^>]*>', caseSensitive: false), '');
    return normalized;
  }

  @override
  State<FormattedContentWidget> createState() => _FormattedContentWidgetState();
}

class _FormattedContentWidgetState extends State<FormattedContentWidget> {
  late bool _isExpanded;
  bool _isOverflowing = false;
  final GlobalKey _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _checkInitialOverflowHeuristic();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(FormattedContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.collapsedMaxLines != widget.collapsedMaxLines ||
        oldWidget.isExpandable != widget.isExpandable) {
      _checkInitialOverflowHeuristic();
      _scheduleMeasure();
    }
  }

  void _checkInitialOverflowHeuristic() {
    if (!widget.isExpandable) {
      _isOverflowing = false;
      return;
    }

    final trimmed = widget.content.trim();
    final lineCount = '\n'.allMatches(trimmed).length + 1;
    if (lineCount > widget.collapsedMaxLines || trimmed.length > 200) {
      _isOverflowing = true;
    } else {
      _isOverflowing = false;
    }
  }

  void _scheduleMeasure() {
    if (!widget.isExpandable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureContentHeight();
    });
  }

  void _measureContentHeight() {
    if (!mounted || !widget.isExpandable) return;
    final renderBox = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final totalHeight = renderBox.size.height;
      final collapsedHeight = widget.fontSize * 1.5 * widget.collapsedMaxLines + 8.0;
      final overflows = totalHeight > (collapsedHeight + 8.0);
      if (overflows != _isOverflowing) {
        setState(() {
          _isOverflowing = overflows;
        });
      }
    }
  }

  Widget _buildContent(BuildContext context, Color defaultColor, {bool forMeasurement = false}) {
    if (widget.content.trim().isEmpty) return const SizedBox.shrink();

    final processedContent = FormattedContentWidget.convertBbcodeToMarkdown(widget.content);
    final hasMarkdown = FormattedContentWidget.isMarkdown(processedContent);
    final hasHtml = FormattedContentWidget.isHtml(processedContent);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child;

    if (hasMarkdown || !hasHtml) {
      final normalizedData = FormattedContentWidget.normalizeMarkdown(processedContent);
      final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: TextStyle(
          fontSize: widget.fontSize,
          height: 1.5,
          color: defaultColor,
        ),
        h1: TextStyle(
          fontSize: widget.fontSize + 6,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h2: TextStyle(
          fontSize: widget.fontSize + 4,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h3: TextStyle(
          fontSize: widget.fontSize + 2,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        h4: TextStyle(
          fontSize: widget.fontSize + 1,
          fontWeight: FontWeight.bold,
          color: defaultColor,
          height: 1.3,
        ),
        code: TextStyle(
          backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
          fontFamily: 'monospace',
          fontSize: widget.fontSize - 1,
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
          fontSize: widget.fontSize,
        ),
      );

      child = MarkdownBody(
        data: normalizedData,
        selectable: forMeasurement ? false : widget.selectable,
        styleSheet: styleSheet,
        onTapLink: forMeasurement
            ? null
            : (text, href, title) {
                if (href != null && href.isNotEmpty) {
                  SafeUrlLauncher.launch(href);
                }
              },
      );
    } else {
      final sanitizedData = FormattedContentWidget.sanitizeHtml(processedContent);
      child = Html(
        data: sanitizedData,
        onLinkTap: forMeasurement
            ? null
            : (url, attributes, element) {
                if (url != null && url.isNotEmpty) {
                  SafeUrlLauncher.launch(url);
                }
              },
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(widget.fontSize),
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

    // Hard maxLines constraint if specified and not expandable
    if (widget.maxLines != null && !widget.isExpandable) {
      final hardMaxHeight = widget.fontSize * 1.5 * widget.maxLines!;
      child = SizedBox(
        height: hardMaxHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            minWidth: 0,
            maxWidth: double.infinity,
            child: child,
          ),
        ),
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.trim().isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = widget.style?.color ??
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);
    final processedContent = FormattedContentWidget.convertBbcodeToMarkdown(widget.content);
    final textDirection = FormattedContentWidget.isArabic(processedContent)
        ? TextDirection.rtl
        : TextDirection.ltr;
    final l10n = AppLocalizations.of(context);

    final collapsedHeight = widget.fontSize * 1.5 * widget.collapsedMaxLines + 8.0;

    // Normal non-expandable rendering
    if (!widget.isExpandable) {
      return Directionality(
        textDirection: textDirection,
        child: _buildContent(context, defaultColor),
      );
    }

    Widget mainContent = _buildContent(context, defaultColor);

    // If collapsing and overflowing, apply height constraint and gradient fade
    if (_isOverflowing && !_isExpanded) {
      Widget collapsedBox = SizedBox(
        height: collapsedHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            minWidth: 0,
            maxWidth: double.infinity,
            child: mainContent,
          ),
        ),
      );

      if (widget.showGradientFade) {
        mainContent = ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.65, 1.0],
              colors: [Colors.black, Colors.black, Colors.transparent],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: collapsedBox,
        );
      } else {
        mainContent = collapsedBox;
      }
    }

    return Directionality(
      textDirection: textDirection,
      child: Stack(
        children: [
          // Background measurement widget (runs offstage when collapsed to track exact overflow)
          if (!_isExpanded)
            Offstage(
              offstage: true,
              child: KeyedSubtree(
                key: _measureKey,
                child: _buildContent(context, defaultColor, forMeasurement: true),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: mainContent,
              ),
              if (_isOverflowing) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final nextState = !_isExpanded;
                    setState(() {
                      _isExpanded = nextState;
                    });
                    widget.onExpandToggled?.call(nextState);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded
                              ? (widget.seeLessLabel ?? l10n?.seeLess ?? 'See less')
                              : (widget.seeMoreLabel ?? l10n?.seeMore ?? 'See more'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: widget.fontSize - 1.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
