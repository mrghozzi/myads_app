import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/status_model.dart';
import '../../../core/providers/feed_provider.dart';
import '../../posts/posts_repository.dart';

class PollWidget extends ConsumerStatefulWidget {
  final StatusModel status;

  const PollWidget({super.key, required this.status});

  @override
  ConsumerState<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends ConsumerState<PollWidget> {
  bool _isVoting = false;
  int? _optimisticVotedOptionId;

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  Future<void> _submitVote(int optionId) async {
    final poll = widget.status.poll;
    if (poll == null || poll.hasVoted || poll.isExpired || _isVoting) return;

    setState(() {
      _isVoting = true;
      _optimisticVotedOptionId = optionId;
    });

    try {
      final repo = PostsRepository();
      final res = await repo.votePoll(poll.id, optionId);

      if (mounted) {
        if (res['success'] == true && res['options'] != null) {
          final List optionsData = res['options'];
          final updatedOptions = optionsData
              .map((e) => PollOptionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          final updatedPoll = poll.copyWith(
            hasVoted: true,
            userVotedOptionId: optionId,
            totalVotes: res['total_votes'] is int
                ? res['total_votes']
                : int.tryParse(res['total_votes']?.toString() ?? '0') ?? (poll.totalVotes + 1),
            options: updatedOptions,
          );

          ref.read(feedProvider.notifier).updatePoll(widget.status.id, updatedPoll);

          final msg = res['message']?.toString() ?? 'تم تسجيل تصويتك بنجاح!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF615DFA),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (res['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'].toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.status.poll;
    if (poll == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final hasVoted = poll.hasVoted || _optimisticVotedOptionId != null;
    final votedOptionId = _optimisticVotedOptionId ?? poll.userVotedOptionId;
    final showResults = hasVoted || poll.isExpired;
    final isAr = _isArabic(poll.question);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge + Votes count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.poll_rounded, size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          isAr ? 'استطلاع رأي' : 'Poll',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (poll.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'منتهي' : 'Ended',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'نشط' : 'Active',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Text(
                '${poll.totalVotes} ${isAr ? "صوت" : "votes"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question
          Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                poll.question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  height: 1.35,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Options List
          ...poll.options.map((opt) {
            final isSelected = (votedOptionId == opt.id);
            final percent = opt.percentage;
            final canVote = !hasVoted && !poll.isExpired && !_isVoting;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canVote ? () => _submitVote(opt.id) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated progress fill when results are shown
                        if (showResults)
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: (percent / 100).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.22)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05)),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Option content row
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: primaryColor, size: 18)
                                else if (!showResults)
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                                    ),
                                  ),
                                if (isSelected || !showResults) const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt.optionText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showResults) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${opt.votesCount} ${isAr ? "صوت" : "votes"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 1)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

