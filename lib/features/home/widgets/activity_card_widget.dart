import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/activity_card_model.dart';

/// Rich activity card widget for Store, Directory, Knowledgebase, and Order posts.
/// Designed to match the web-side activity card appearance within Flutter's design system.
class ActivityCardWidget extends StatelessWidget {
  final ActivityCardModel card;

  const ActivityCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: switch (card.kind) {
        'store' => _StoreCard(card: card),
        'directory' => _DirectoryCard(card: card),
        'knowledgebase' => _KnowledgebaseCard(card: card),
        'order' => _OrderCard(card: card),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final ActivityCardModel card;
  const _StoreCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2236) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? const Color(0xFF253050) : const Color(0xFFF1F5F9),
                  child: Icon(Icons.shopping_bag_outlined, size: 48,
                      color: isDark ? Colors.white24 : Colors.black12),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price badge
                _buildPriceBadge(isDark),
                const SizedBox(height: 8),
                // Title
                Text(
                  card.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Category badges
                if (card.badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: card.badges.map((b) => _BadgeChip(badge: b)).toList(),
                  ),
                ],
                // Description
                if (card.description != null && card.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    card.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // CTA
                const SizedBox(height: 12),
                _CtaButton(
                  label: card.ctaLabel ?? 'View',
                  url: card.primaryUrl,
                  icon: Icons.shopping_bag_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(bool isDark) {
    final price = card.price;
    if (price == null) return const SizedBox.shrink();

    if (price.isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
        ),
        child: const Text(
          'FREE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4CAF50),
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final accentColor = price.isOnSale
        ? const Color(0xFFF34141)
        : const Color(0xFF615DFA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accentColor.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (price.isOnSale && price.original != null) ...[
            Text(
              '${price.original} PTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${price.current} PTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIRECTORY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DirectoryCard extends StatelessWidget {
  final ActivityCardModel card;
  const _DirectoryCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2236) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image with category overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark ? const Color(0xFF253050) : const Color(0xFFF1F5F9),
                          child: Icon(Icons.public, size: 48,
                              color: isDark ? Colors.white24 : Colors.black12),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E3A5F), const Color(0xFF0F172A)]
                                : [const Color(0xFFE0F2FE), const Color(0xFFF0F9FF)],
                          ),
                        ),
                        child: Icon(Icons.public, size: 48,
                            color: isDark ? Colors.white24 : Colors.black12),
                      ),
              ),
              // Category overlay badge
              if (card.badges.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          card.badges.first.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  card.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Description
                if (card.description != null && card.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    card.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Footer: views + CTA
                Row(
                  children: [
                    // Views count
                    if (card.meta.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 14,
                              color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            card.meta.first.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    _CtaButton(
                      label: card.ctaLabel ?? 'Visit',
                      url: card.externalUrl ?? card.primaryUrl,
                      icon: Icons.open_in_new,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KNOWLEDGEBASE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _KnowledgebaseCard extends StatelessWidget {
  final ActivityCardModel card;
  const _KnowledgebaseCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2236) : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
              : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          if (card.badges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: card.badges.map((b) => _BadgeChip(badge: b)).toList(),
            ),
          const SizedBox(height: 10),
          // Title
          Text(
            card.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Description
          if (card.description != null && card.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.description!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Meta + CTA row
          Row(
            children: [
              // Meta items (author)
              ...card.meta.map((m) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.icon == 'user' ? Icons.person_outline : Icons.info_outline,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  )),
              const Spacer(),
              _CtaButton(
                label: card.ctaLabel ?? 'Read',
                url: card.primaryUrl,
                icon: Icons.menu_book_rounded,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final ActivityCardModel card;
  const _OrderCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2236) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge chips row
          if (card.badges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.badges.map((b) => _BadgeChip(badge: b)).toList(),
            ),
          const SizedBox(height: 12),
          // Title
          Text(
            card.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Description
          if (card.description != null && card.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.description!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          // CTA
          _CtaButton(
            label: card.ctaLabel ?? 'View Details',
            url: card.primaryUrl,
            icon: Icons.work_outline_rounded,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final ActivityBadge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = _getColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color) _getColors(bool isDark) {
    return switch (badge.tone) {
      'primary' => (
          isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFFEEF2FF),
          isDark ? const Color(0xFF60A5FA) : const Color(0xFF3F4A7A),
        ),
      'success' => (
          isDark ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFECFDF5),
          isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
        ),
      'warning' => (
          isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFFFFBEB),
          isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
        ),
      'danger' => (
          isDark ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
          isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
        ),
      _ => (
          isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF7F8FF),
          isDark ? Colors.white70 : const Color(0xFF5B6380),
        ),
    };
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final String? url;
  final IconData icon;
  final bool compact;

  const _CtaButton({
    required this.label,
    this.url,
    required this.icon,
    this.compact = false,
  });

  Future<void> _openUrl() async {
    if (url == null || url!.isEmpty) return;
    final uri = Uri.tryParse(url!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (compact) {
      return GestureDetector(
        onTap: _openUrl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: primary),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openUrl,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
