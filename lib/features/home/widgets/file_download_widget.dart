import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/attachment_model.dart';

/// File download widget with progress indicator and open-file support.
class FileDownloadWidget extends StatefulWidget {
  final List<AttachmentModel> attachments;

  const FileDownloadWidget({super.key, required this.attachments});

  @override
  State<FileDownloadWidget> createState() => _FileDownloadWidgetState();
}

class _FileDownloadWidgetState extends State<FileDownloadWidget> {
  final Map<int, _DownloadState> _states = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attachments = widget.attachments;

    if (attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: attachments.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          final state = _states[index] ?? _DownloadState.idle;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFileItem(context, isDark, file, index, state),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    bool isDark,
    AttachmentModel file,
    int index,
    _DownloadState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // File icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _getIconColor(state).withValues(alpha: 0.12),
                ),
                child: Icon(
                  _getIcon(state),
                  color: _getIconColor(state),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name ?? 'File',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (file.size > 0)
                      Text(
                        file.humanSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
              // Action button
              _buildActionButton(context, isDark, file, index, state),
            ],
          ),
          // Progress bar
          if (state.isDownloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 4,
              ),
            ),
          ],
          // Error message
          if (state.isError) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Download failed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openExternally(file.url),
                  child: Text(
                    'Open in browser',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isDark,
    AttachmentModel file,
    int index,
    _DownloadState state,
  ) {
    if (state.isDownloading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: state.progress,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (state.isCompleted) {
      return GestureDetector(
        onTap: () => _openFile(state.filePath!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 14, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 4),
              Text(
                'Open',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _startDownload(file, index),
      child: Icon(
        Icons.download_rounded,
        color: isDark ? Colors.white38 : Colors.black38,
        size: 22,
      ),
    );
  }

  IconData _getIcon(_DownloadState state) {
    if (state.isCompleted) return Icons.check_circle_rounded;
    if (state.isError) return Icons.error_outline_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconColor(_DownloadState state) {
    if (state.isCompleted) return const Color(0xFF4CAF50);
    if (state.isError) return Colors.red;
    return const Color(0xFF607D8B);
  }

  Future<void> _startDownload(AttachmentModel file, int index) async {
    setState(() {
      _states[index] = _DownloadState.downloading();
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = file.name ?? 'download_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${dir.path}/$fileName';

      await Dio().download(
        file.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _states[index] = _DownloadState.downloading(
                progress: received / total,
              );
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _states[index] = _DownloadState.completed(filePath);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _states[index] = _DownloadState.error();
        });
      }
    }
  }

  Future<void> _openFile(String path) async {
    await OpenFilex.open(path);
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

enum _DownloadStatus { idle, downloading, completed, error }

class _DownloadState {
  final _DownloadStatus status;
  final double? progress;
  final String? filePath;

  const _DownloadState._({
    required this.status,
    this.progress,
    this.filePath,
  });

  static const idle = _DownloadState._(status: _DownloadStatus.idle);

  factory _DownloadState.downloading({double? progress}) =>
      _DownloadState._(status: _DownloadStatus.downloading, progress: progress);

  factory _DownloadState.completed(String path) =>
      _DownloadState._(status: _DownloadStatus.completed, filePath: path);

  factory _DownloadState.error() =>
      _DownloadState._(status: _DownloadStatus.error);

  bool get isIdle => status == _DownloadStatus.idle;
  bool get isDownloading => status == _DownloadStatus.downloading;
  bool get isCompleted => status == _DownloadStatus.completed;
  bool get isError => status == _DownloadStatus.error;
}
