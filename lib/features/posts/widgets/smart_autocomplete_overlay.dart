import 'dart:async';
import 'package:flutter/material.dart';
import '../posts_repository.dart';

enum AutocompleteType { none, mention, tag }

class SmartAutocompleteOverlay extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSelected;

  const SmartAutocompleteOverlay({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSelected,
  });

  @override
  State<SmartAutocompleteOverlay> createState() => _SmartAutocompleteOverlayState();
}

class _SmartAutocompleteOverlayState extends State<SmartAutocompleteOverlay> {
  final PostsRepository _repository = PostsRepository();
  Timer? _debounceTimer;
  AutocompleteType _activeType = AutocompleteType.none;
  String _currentQuery = '';
  int _tokenStartIndex = -1;
  int _tokenEndIndex = -1;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset < 0) {
      _dismissSuggestions();
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition == 0) {
      _dismissSuggestions();
      return;
    }

    // Find the current token under or immediately before cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpace = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final tokenStart = lastSpace == -1 ? 0 : lastSpace + 1;
    final currentToken = textBeforeCursor.substring(tokenStart);

    if (currentToken.startsWith('@') && currentToken.length > 1) {
      final query = currentToken.substring(1);
      _activeType = AutocompleteType.mention;
      _currentQuery = query;
      _tokenStartIndex = tokenStart;
      _tokenEndIndex = cursorPosition;
      _queueFetch(query, AutocompleteType.mention);
    } else if (currentToken.startsWith('#') && currentToken.length > 1) {
      final query = currentToken.substring(1);
      _activeType = AutocompleteType.tag;
      _currentQuery = query;
      _tokenStartIndex = tokenStart;
      _tokenEndIndex = cursorPosition;
      _queueFetch(query, AutocompleteType.tag);
    } else {
      _dismissSuggestions();
    }
  }

  void _queueFetch(String query, AutocompleteType type) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        List<Map<String, dynamic>> results = [];
        if (type == AutocompleteType.mention) {
          results = await _repository.suggestUsers(query);
        } else if (type == AutocompleteType.tag) {
          results = await _repository.suggestTags(query);
        }

        if (mounted && _activeType == type && _currentQuery == query) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  void _dismissSuggestions() {
    if (_activeType != AutocompleteType.none || _suggestions.isNotEmpty || _isLoading) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _activeType = AutocompleteType.none;
          _suggestions = [];
          _isLoading = false;
          _currentQuery = '';
        });
      }
    }
  }

  void _applySelection(String replacement) {
    final text = widget.controller.text;
    if (_tokenStartIndex < 0 || _tokenStartIndex > text.length) return;

    final before = text.substring(0, _tokenStartIndex);
    final after = text.substring(_tokenEndIndex);
    final inserted = '$replacement ';
    final newText = '$before$inserted$after';
    final newCursor = before.length + inserted.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    widget.onSelected?.call(replacement);
    _dismissSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeType == AutocompleteType.none || (_suggestions.isEmpty && !_isLoading)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(
                    _activeType == AutocompleteType.mention ? Icons.alternate_email : Icons.tag,
                    size: 14,
                    color: const Color(0xFF615DFA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _activeType == AutocompleteType.mention
                        ? 'Suggested Users'
                        : 'Suggested Hashtags',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF615DFA),
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF615DFA)),
                    ),
                ],
              ),
            ),
            // Suggestions list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];

                  if (_activeType == AutocompleteType.mention) {
                    final username = item['username']?.toString() ?? '';
                    final avatar = item['avatar']?.toString();

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF615DFA).withValues(alpha: 0.15),
                        backgroundImage: avatar != null && avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                        child: (avatar == null || avatar.isEmpty)
                            ? Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF615DFA)),
                              )
                            : null,
                      ),
                      title: Text(
                        '@$username',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _applySelection('@$username'),
                    );
                  } else {
                    final tag = item['tag']?.toString() ?? item['display']?.toString().replaceFirst('#', '') ?? '';
                    final count = item['count'];

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23D2E2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tag, size: 16, color: Color(0xFF23D2E2)),
                      ),
                      title: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      trailing: count != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count posts',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _applySelection('#$tag'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
