import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'posts_repository.dart';
import '../../core/models/status_model.dart';
import 'package:path/path.dart' as p;

final composerProvider = Provider((ref) => PostsRepository());

class ComposerScreen extends ConsumerStatefulWidget {
  final StatusModel? initialStatus;
  final String? initialText;
  final List<String>? initialFilePaths;

  const ComposerScreen({
    super.key,
    this.initialStatus,
    this.initialText, this.initialFilePaths});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final TextEditingController _textController = TextEditingController();
  List<File> _selectedFiles = [];
  bool _isLoading = false;
  String _postKind = 'text';

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _textController.text = widget.initialStatus!.text;
      _postKind = widget.initialStatus!.postKind;
    } else if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
    
    if (widget.initialFilePaths != null) {
      _selectedFiles = widget.initialFilePaths!.map((path) => File(path)).toList();
      if (_selectedFiles.isNotEmpty && _postKind == 'text') {
        _postKind = 'gallery'; 
      }
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.where((path) => path != null).map((path) => File(path!)));
        if (_postKind == 'text') _postKind = 'gallery';
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(composerProvider);
      
      final formData = FormData.fromMap({
        'text': _textController.text,
        'post_kind': _postKind,
      });

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
        if (mounted) context.pop(true); 
      } else {
        await repo.createPost(formData);
        if (mounted) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMediaPreview(File file) {
    bool isImage = _postKind == 'gallery' || p.extension(file.path).toLowerCase() == '.jpg' || p.extension(file.path).toLowerCase() == '.png' || p.extension(file.path).toLowerCase() == '.jpeg';
    return Stack(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
            image: isImage ? DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ) : null,
          ),
          child: !isImage ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _postKind == 'video' ? Icons.movie_outlined : 
                _postKind == 'audio' ? Icons.audiotrack_outlined : 
                Icons.insert_drive_file_outlined,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  p.basename(file.path),
                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ) : null,
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFiles.remove(file);
                if (_selectedFiles.isEmpty && _postKind != 'text') {
                  _postKind = 'text';
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialStatus == null ? 'Create Post' : 'Edit Post', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            minLines: 5,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _selectedFiles.map((f) => _buildMediaPreview(f)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.photo_library_outlined, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      _postKind = 'gallery';
                      _pickFiles();
                    },
                    tooltip: 'Image',
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam_outlined, color: Colors.red[400]),
                    onPressed: () {
                      _postKind = 'video';
                      _pickFiles();
                    },
                    tooltip: 'Video',
                  ),
                  IconButton(
                    icon: Icon(Icons.mic_none_outlined, color: Colors.orange[400]),
                    onPressed: () {
                      _postKind = 'audio';
                      _pickFiles();
                    },
                    tooltip: 'Audio',
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file_outlined, color: Colors.green[400]),
                    onPressed: () {
                      _postKind = 'file';
                      _pickFiles();
                    },
                    tooltip: 'File',
                  ),
                  const Spacer(),
                  // Post kind indicator chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _postKind.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

