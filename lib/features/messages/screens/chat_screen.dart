import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myads_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/hexagon_avatar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String username;
  const ChatScreen({super.key, required this.username});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  List<dynamic> _messages = [];
  Map<String, dynamic>? _partner;
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  bool _showEmojiPicker = false;
  bool _isSending = false;

  List<CategoryEmoji> _customEmojiSet(Locale locale) {
    final List<String> hiddenEmojis = ['🇮🇱', '🏳️‍🌈', '🏳️‍⚧️', '🏴‍☠️'];
    final List<CategoryEmoji> defaultSet = getDefaultEmojiLocale(locale);
    
    return defaultSet.map((category) {
      return CategoryEmoji(
        category.category,
        category.emoji.where((emoji) {
          final str = emoji.emoji;
          for (final hidden in hiddenEmojis) {
            if (str.contains(hidden) || hidden.contains(str)) {
              return false;
            }
          }
          return true;
        }).toList(),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollUpdates();
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await ApiClient.instance.get('/messages/${widget.username}');
      if (mounted) {
        setState(() {
          _partner = response.data['partner'];
          _messages = response.data['messages'] ?? [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pollUpdates() async {
    if (_messages.isEmpty) return;
    
    // In MYADS, newerMessages logic relies on after_id
    final lastMessageId = _messages.last['id_msg'] ?? _messages.last['id'] ?? 0;
    try {
      final response = await ApiClient.instance.get('/messages/updates?conversation=${widget.username}&after_id=$lastMessageId');
      final newMessages = response.data['active_messages'] ?? [];
      if (newMessages.isNotEmpty && mounted) {
        setState(() {
          _messages.addAll(newMessages);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final response = await ApiClient.instance.post('/messages/${widget.username}', data: {
        'message': text,
      });
      if (mounted && response.data['success'] == true) {
        setState(() {
          _messages.add(response.data['data']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendAttachment() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        setState(() => _isSending = true);

        final formData = FormData.fromMap({
          'attachment': await MultipartFile.fromFile(filePath, filename: fileName),
          'message': '', 
        });

        final response = await ApiClient.instance.post('/messages/${widget.username}', data: formData);
        
        if (mounted && response.data['success'] == true) {
          setState(() {
            _messages.add(response.data['data']);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send attachment')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _partner == null
            ? Text('@${widget.username}')
            : Row(
                children: [
                  HexagonAvatar(
                    avatarUrl: _partner!['avatar'] ?? '',
                    size: 32,
                    isOnline: _partner!['online'] == true,
                    isVerified: _partner!['is_verified'] == true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _partner!['name'] ?? _partner!['username'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_partner!['online'] == true)
                          const Text('Active now', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
        elevation: 1,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final partnerId = _partner != null ? _partner!['id'] : null;
                        // Handle both nested 'sender' object and flat 'us_env' field formats
                        final sender = msg['sender'];
                        final bool isMe;
                        if (sender != null && sender is Map) {
                          isMe = sender['id'] != partnerId;
                        } else if (msg['us_env'] != null && partnerId != null) {
                          isMe = msg['us_env'] != partnerId;
                        } else {
                          isMe = true;
                        }
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe 
                                  ? const Color(0xFF615dfa) 
                                  : (isDark ? const Color(0xFF2d323e) : const Color(0xFFe9ecef)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'] ?? msg['msg'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                    fontSize: 15,
                                  ),
                                ),
                                if (msg['attachment_path'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        // Attachment view handling logic
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.attachment, size: 16, color: isMe ? Colors.white70 : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            msg['attachment_name'] ?? 'Attachment',
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : Colors.grey,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: const Color(0xFF23d2e2)
                          ),
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                              if (_showEmojiPicker) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Color(0xFF23d2e2)),
                          onPressed: _isSending ? null : _pickAndSendAttachment,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: l10n.typeMessage,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2d323e) : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                        IconButton(
                          icon: _isSending 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: Color(0xFF615dfa)),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ),
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        textEditingController: _textController,
                        config: Config(
                          emojiSet: _customEmojiSet,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
