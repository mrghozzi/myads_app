import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'posts_repository.dart';
import '../../core/models/status_model.dart';
import '../../core/widgets/hexagon_avatar.dart';
import '../../features/profile/profile_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

final composerProvider = Provider((ref) => PostsRepository());

class ComposerScreen extends ConsumerStatefulWidget {
  final StatusModel? initialStatus;
  final String? initialText;
  final String? initialLinkUrl;
  final List<String>? initialFilePaths;
  final StatusModel? initialRepostStatus;
  final int? initialRepostStatusId;
  final int? initialGroupId;

  const ComposerScreen({
    super.key,
    this.initialStatus,
    this.initialText,
    this.initialLinkUrl,
    this.initialFilePaths,
    this.initialRepostStatus,
    this.initialRepostStatusId,
    this.initialGroupId,
  });

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();
  final TextEditingController _directoryNameController = TextEditingController();
  final TextEditingController _directoryTagsController = TextEditingController();

  List<File> _selectedFiles = [];
  bool _isLoading = false;
  bool _isFetchingPreview = false;
  bool _showMoreTools = false;

  String _postKind = 'text'; // text, gallery, video, audio, music, file, clips, link, repost
  String _publishMode = 'post'; // post, directory_only
  
  Map<String, dynamic>? _linkPreview;
  String? _autoDetectedLink;
  Timer? _previewDebounce;

  StatusModel? _repostStatus;
  int? _repostStatusId;
  int? _selectedGroupId;

  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _directoryCategories = [];
  int? _selectedDirectoryCategoryId;

  @override
  void initState() {
    super.initState();

    _repostStatus = widget.initialRepostStatus;
    _repostStatusId = widget.initialRepostStatusId ?? widget.initialRepostStatus?.id;
    _selectedGroupId = widget.initialGroupId;

    if (widget.initialStatus != null) {
      final s = widget.initialStatus!;
      _textController.text = s.text;
      _postKind = s.postKind;
      if (s.repostStatusId != null) {
        _repostStatusId = s.repostStatusId;
      }
    } else if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }

    if (widget.initialLinkUrl != null && widget.initialLinkUrl!.isNotEmpty) {
      _linkUrlController.text = widget.initialLinkUrl!;
      _postKind = 'link';
      _fetchPreview(widget.initialLinkUrl!);
    }

    if (widget.initialFilePaths != null) {
      _selectedFiles = widget.initialFilePaths!.map((path) => File(path)).toList();
      if (_selectedFiles.isNotEmpty && _postKind == 'text') {
        _postKind = 'gallery';
      }
    }

    if (_repostStatusId != null && _repostStatusId! > 0) {
      _postKind = 'repost';
    }

    _textController.addListener(_onTextChanged);
    _linkUrlController.addListener(_onLinkUrlChanged);

    _loadComposerOptions();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _textController.dispose();
    _linkUrlController.dispose();
    _directoryNameController.dispose();
    _directoryTagsController.dispose();
    super.dispose();
  }

  Future<void> _loadComposerOptions() async {
    try {
      final repo = ref.read(composerProvider);
      final options = await repo.getComposerOptions();

      if (mounted) {
        setState(() {
          if (options['groups'] is List) {
            _userGroups = List<Map<String, dynamic>>.from(options['groups']);
          }
          if (options['directory_categories'] is List) {
            _directoryCategories = List<Map<String, dynamic>>.from(options['directory_categories']);
            if (_directoryCategories.isNotEmpty) {
              _selectedDirectoryCategoryId = _directoryCategories.first['id'] as int?;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _onTextChanged() {
    final text = _textController.text;
    final urlMatch = RegExp(r'\b((https?://)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/\S*)?)\b', caseSensitive: false).firstMatch(text);
    
    if (urlMatch != null) {
      String detected = urlMatch.group(1)!;
      if (!detected.startsWith('http://') && !detected.startsWith('https://')) {
        detected = 'https://$detected';
      }
      if (detected != _autoDetectedLink) {
        _autoDetectedLink = detected;
        if (_linkUrlController.text.isEmpty || _linkUrlController.text == _autoDetectedLink) {
          _linkUrlController.text = detected;
        }
      }
    }
    setState(() {});
  }

  void _onLinkUrlChanged() {
    final url = _linkUrlController.text.trim();
    if (url.isNotEmpty && url.contains('.')) {
      _previewDebounce?.cancel();
      _previewDebounce = Timer(const Duration(milliseconds: 600), () {
        _fetchPreview(url);
      });
    } else if (url.isEmpty) {
      setState(() {
        _linkPreview = null;
        if (_postKind == 'link') _postKind = 'text';
      });
    }
  }

  Future<void> _fetchPreview(String url) async {
    if (_isFetchingPreview) return;
    setState(() => _isFetchingPreview = true);

    try {
      final repo = ref.read(composerProvider);
      final preview = await repo.fetchLinkPreview(url);
      if (mounted) {
        setState(() {
          _linkPreview = preview;
          if (_postKind == 'text' || _postKind == 'link') {
            _postKind = 'link';
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isFetchingPreview = false);
    }
  }

  Future<void> _pickFiles(FileType type, String targetKind, {bool allowMultiple = false}) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: type,
        allowMultiple: allowMultiple,
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          final files = result.paths.where((p) => p != null).map((p) => File(p!)).toList();
          if (allowMultiple) {
            _selectedFiles.addAll(files);
          } else {
            _selectedFiles = files;
          }
          _postKind = targetKind;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick files: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(composerProvider);

      final map = <String, dynamic>{
        'text': _textController.text.trim(),
        'post_kind': _postKind,
        'publish_mode': _publishMode,
      };

      if (_selectedGroupId != null && _selectedGroupId! > 0) {
        map['group_id'] = _selectedGroupId;
      }

      if (_repostStatusId != null && _repostStatusId! > 0) {
        map['repost_status_id'] = _repostStatusId;
      }

      if (_linkUrlController.text.trim().isNotEmpty) {
        map['link_url'] = _linkUrlController.text.trim();
      }

      if (_publishMode == 'directory_only') {
        if (_directoryNameController.text.trim().isNotEmpty) {
          map['directory_name'] = _directoryNameController.text.trim();
        }
        if (_selectedDirectoryCategoryId != null) {
          map['directory_category_id'] = _selectedDirectoryCategoryId;
        }
        if (_directoryTagsController.text.trim().isNotEmpty) {
          map['directory_tags'] = _directoryTagsController.text.trim();
        }
      }

      final formData = FormData.fromMap(map);

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        String fieldName = 'files[$i]';

        if (_postKind == 'gallery') {
          fieldName = 'images[$i]';
        } else if (_postKind == 'video' || _postKind == 'clips') {
          fieldName = 'videos[$i]';
        } else if (_postKind == 'audio' || _postKind == 'music') {
          fieldName = 'audios[$i]';
        }

        formData.files.add(MapEntry(
          fieldName,
          await MultipartFile.fromFile(file.path, filename: p.basename(file.path)),
        ));
      }

      if (widget.initialStatus != null) {
        await repo.updatePost(widget.initialStatus!.id, formData);
      } else {
        await repo.createPost(formData);
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearMedia() {
    setState(() {
      _selectedFiles.clear();
      if (_postKind != 'link' && _postKind != 'repost') {
        _postKind = 'text';
      }
    });
  }

  void _clearLink() {
    setState(() {
      _linkUrlController.clear();
      _linkPreview = null;
      _autoDetectedLink = null;
      if (_postKind == 'link') _postKind = 'text';
    });
  }

  void _clearRepost() {
    setState(() {
      _repostStatus = null;
      _repostStatusId = null;
      if (_postKind == 'repost') _postKind = 'text';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(profileDetailProvider('me'));

    final surfaceColor = isDark ? const Color(0xFF1F2436) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF);
    final borderColor = isDark ? const Color(0xFF313951) : const Color(0xFFE7EAF5);
    final primaryColor = const Color(0xFF615DFA);
    final textColor = isDark ? const Color(0xFFF5F7FF) : const Color(0xFF2F3142);
    final mutedColor = isDark ? const Color(0xFFA2ACC7) : const Color(0xFF8A90A9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          widget.initialStatus == null ? l10n.createPost : l10n.editPost,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.spread, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Identity Header & Target Context
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              userAsync.when(
                                data: (u) => HexagonAvatar(
                                  avatarUrl: u.avatar,
                                  size: 44,
                                  isVerified: u.verified,
                                  profileBadgeColor: u.profileBadgeColor,
                                ),
                                loading: () => const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                                error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    userAsync.when(
                                      data: (u) => Text(
                                        u.username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                      loading: () => const SizedBox(),
                                      error: (_, __) => const Text('User'),
                                    ),
                                    if (_userGroups.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int?>(
                                            isDense: true,
                                            value: _selectedGroupId,
                                            dropdownColor: surfaceColor,
                                            items: [
                                              DropdownMenuItem<int?>(
                                                value: null,
                                                child: Text('🌐 Public Community Feed', style: TextStyle(fontSize: 12, color: mutedColor)),
                                              ),
                                              ..._userGroups.map((g) => DropdownMenuItem<int?>(
                                                value: g['id'] as int,
                                                child: Text('👥 ${g['name']}', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                                              )),
                                            ],
                                            onChanged: (val) => setState(() => _selectedGroupId = val),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _postKind.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Editor Text Area
                          TextField(
                            controller: _textController,
                            maxLines: null,
                            minLines: 4,
                            style: TextStyle(fontSize: 16, color: textColor),
                            decoration: InputDecoration(
                              hintText: l10n.whatsOnYourMind,
                              hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.7)),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quote Repost Preview Card
                    if (_repostStatus != null || _repostStatusId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.format_quote, color: primaryColor, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.quoteRepost,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                  Text(
                                    _repostStatus?.text ?? 'Quoted Post #$_repostStatusId',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: textColor),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _clearRepost,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Link URL & Live Preview Card
                    if (_postKind == 'link' || _linkUrlController.text.isNotEmpty || _linkPreview != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.link, color: Color(0xFF00B2FF), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _linkUrlController,
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'https://example.com',
                                      hintStyle: TextStyle(color: mutedColor),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_isFetchingPreview)
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                else if (_linkUrlController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: _clearLink,
                                  ),
                              ],
                            ),
                            if (_linkPreview != null) ...[
                              const Divider(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF262D42) : const Color(0xFFF5F7FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_linkPreview!['image_url'] != null && _linkPreview!['image_url'].toString().isNotEmpty)
                                      Image.network(
                                        _linkPreview!['image_url'],
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _linkPreview!['title'] ?? _linkPreview!['domain'] ?? '',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_linkPreview!['description'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                _linkPreview!['description'],
                                                style: TextStyle(fontSize: 12, color: mutedColor),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              _linkPreview!['domain'] ?? '',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Directory Publishing Selector
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: Text(l10n.publishAsPost),
                                    selected: _publishMode == 'post',
                                    selectedColor: primaryColor.withValues(alpha: 0.2),
                                    onSelected: (sel) {
                                      if (sel) setState(() => _publishMode = 'post');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: Text(l10n.saveToDirectory),
                                    selected: _publishMode == 'directory_only',
                                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    onSelected: (sel) {
                                      if (sel) setState(() => _publishMode = 'directory_only');
                                    },
                                  ),
                                ),
                              ],
                            ),

                            if (_publishMode == 'directory_only') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _directoryNameController,
                                decoration: InputDecoration(
                                  labelText: l10n.directoryName,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_directoryCategories.isNotEmpty)
                                DropdownButtonFormField<int>(
                                  initialValue: _selectedDirectoryCategoryId,
                                  decoration: InputDecoration(
                                    labelText: l10n.directoryCategory,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    isDense: true,
                                  ),
                                  items: _directoryCategories.map((cat) => DropdownMenuItem<int>(
                                    value: cat['id'] as int,
                                    child: Text(cat['name'] ?? ''),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedDirectoryCategoryId = val),
                                ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _directoryTagsController,
                                decoration: InputDecoration(
                                  labelText: l10n.directoryTags,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Media Files Preview
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Attached Files (${_selectedFiles.length})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          TextButton(
                            onPressed: _clearMedia,
                            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _selectedFiles.map((file) => _buildFileCard(file, isDark, primaryColor, textColor, mutedColor)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Color-Coded Toolbar (.superdesign aesthetics)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_showMoreTools) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildToolIconButton(
                            icon: Icons.music_note,
                            label: l10n.uploadMusic,
                            color: const Color(0xFF00D7D2),
                            onTap: () => _pickFiles(FileType.audio, 'music'),
                          ),
                          _buildToolIconButton(
                            icon: Icons.insert_drive_file,
                            label: l10n.uploadFiles,
                            color: const Color(0xFF64748B),
                            onTap: () => _pickFiles(FileType.any, 'file', allowMultiple: true),
                          ),
                          _buildToolIconButton(
                            icon: Icons.movie_filter,
                            label: l10n.uploadClips,
                            color: const Color(0xFFFFB100),
                            onTap: () => _pickFiles(FileType.video, 'clips'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 12),
                  ],
                  Row(
                    children: [
                      _buildToolIconButton(
                        icon: Icons.mode_edit,
                        label: l10n.writePost,
                        color: primaryColor,
                        isActive: _postKind == 'text',
                        onTap: () => setState(() => _postKind = 'text'),
                      ),
                      _buildToolIconButton(
                        icon: Icons.photo_library,
                        label: l10n.uploadPhotos,
                        color: primaryColor,
                        isActive: _postKind == 'gallery',
                        onTap: () => _pickFiles(FileType.image, 'gallery', allowMultiple: true),
                      ),
                      _buildToolIconButton(
                        icon: Icons.videocam,
                        label: l10n.uploadVideo,
                        color: const Color(0xFF615DFA),
                        isActive: _postKind == 'video',
                        onTap: () => _pickFiles(FileType.video, 'video'),
                      ),
                      _buildToolIconButton(
                        icon: Icons.mic,
                        label: l10n.recordAudio,
                        color: const Color(0xFFFF5E3A),
                        isActive: _postKind == 'audio',
                        onTap: () => _pickFiles(FileType.audio, 'audio'),
                      ),
                      _buildToolIconButton(
                        icon: Icons.link,
                        label: l10n.insertLink,
                        color: const Color(0xFF00B2FF),
                        isActive: _postKind == 'link',
                        onTap: () {
                          setState(() {
                            _postKind = 'link';
                            if (_linkUrlController.text.isEmpty) {
                              _linkUrlController.text = 'https://';
                            }
                          });
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_showMoreTools ? Icons.close : Icons.add_circle_outline, color: primaryColor),
                        onPressed: () => setState(() => _showMoreTools = !_showMoreTools),
                        tooltip: l10n.more,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolIconButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(File file, bool isDark, Color primaryColor, Color textColor, Color mutedColor) {
    final ext = p.extension(file.path).toLowerCase();
    final isImg = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);

    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF262D42) : Colors.grey[200],
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            image: isImg
                ? DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !isImg
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ext.contains('mp4') || ext.contains('mov') ? Icons.movie : Icons.insert_drive_file,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        p.basename(file.path),
                        style: TextStyle(fontSize: 9, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFiles.remove(file);
                if (_selectedFiles.isEmpty && _postKind != 'link' && _postKind != 'repost') {
                  _postKind = 'text';
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xB3000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
