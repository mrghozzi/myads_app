import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/status_model.dart';
import '../../core/network/api_client.dart';
import '../home/widgets/post_card.dart';
import 'profile_provider.dart';
import '../../core/widgets/hexagon_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const ProfileScreen({super.key, this.username = 'me'});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Local state for statuses (pagination)
  final List<StatusModel> _statuses = [];
  bool _isLoadingStatuses = true;
  bool _isLoadingMoreStatuses = false;
  bool _hasMoreStatuses = true;
  int _currentStatusesPage = 1;
  String? _statusesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add pagination listener for statuses
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMoreStatuses && _hasMoreStatuses && !_isLoadingStatuses) {
          _fetchStatuses(_currentStatusesPage + 1);
        }
      }
    });

    _fetchStatuses(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatuses(int page, {bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoadingStatuses = true;
        _statusesError = null;
        _hasMoreStatuses = true;
        _currentStatusesPage = 1;
      });
    } else if (page > 1) {
      setState(() {
        _isLoadingMoreStatuses = true;
      });
    }

    try {
      final response = await ApiClient.instance.get(
        '/profile/${widget.username}/statuses',
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data is! Map || !data.containsKey('data')) {
        throw Exception('Server returned invalid format');
      }

      final List itemsJson = data['data'] ?? [];
      final newItems = itemsJson.map((e) => StatusModel.fromJson(e)).toList();

      final meta = data['meta'];
      bool hasMore = false;
      if (meta != null && meta is Map) {
        final currentPage = meta['current_page'] ?? 1;
        final lastPage = meta['last_page'] ?? 1;
        hasMore = currentPage < lastPage;
      } else {
        final currentPage = data['current_page'] ?? 1;
        final lastPage = data['last_page'] ?? 1;
        hasMore = currentPage < lastPage;
      }

      if (mounted) {
        setState(() {
          if (isRefresh || page == 1) {
            _statuses.clear();
          }
          _statuses.addAll(newItems);
          _currentStatusesPage = page;
          _hasMoreStatuses = hasMore;
          _isLoadingStatuses = false;
          _isLoadingMoreStatuses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (page == 1) {
            _statusesError = e.toString();
            _isLoadingStatuses = false;
          } else {
            _isLoadingMoreStatuses = false;
          }
        });
      }
    }
  }

  Color _parseHexColor(String hexStr, Color fallback) {
    if (hexStr.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hexStr.length == 6 || hexStr.length == 7) buffer.write('ff');
      buffer.write(hexStr.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  void _launchUrlString(String urlString) async {
    if (urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching link: $e')),
        );
      }
    }
  }

  IconData _getBadgeIcon(String iconName) {
    final name = iconName.toLowerCase();
    if (name.contains('crown')) return Icons.workspace_premium;
    if (name.contains('star')) return Icons.star;
    if (name.contains('shield') || name.contains('moderator')) return Icons.shield;
    if (name.contains('trophy') || name.contains('award')) return Icons.emoji_events;
    if (name.contains('bolt') || name.contains('zap')) return Icons.electric_bolt;
    if (name.contains('heart') || name.contains('love')) return Icons.favorite;
    if (name.contains('comment')) return Icons.comment;
    if (name.contains('post')) return Icons.post_add;
    if (name.contains('person') || name.contains('user')) return Icons.person;
    return Icons.military_tech;
  }

  Widget _buildSocialIcon(String platform, String url) {
    IconData icon;
    Color color;
    switch (platform) {
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'twitter':
        icon = Icons.alternate_email;
        color = Colors.black;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = const Color(0xFFE4405F);
        break;
      case 'youtube':
        icon = Icons.video_library;
        color = const Color(0xFFFF0000);
        break;
      case 'linkedin':
        icon = Icons.business;
        color = const Color(0xFF0077B5);
        break;
      case 'github':
        icon = Icons.code;
        color = const Color(0xFF24292E);
        break;
      case 'tiktok':
        icon = Icons.music_note;
        color = const Color(0xFFFE2C55);
        break;
      case 'discord':
        icon = Icons.forum;
        color = const Color(0xFF5865F2);
        break;
      default:
        icon = Icons.link;
        color = const Color(0xFF615DFA);
    }

    return GestureDetector(
      onTap: () => _launchUrlString(url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDetailProvider(widget.username));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.username == 'me' ? 'My Profile' : '@${widget.username}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.username != 'me' 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (widget.username == 'me')
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: profileAsync.when(
        data: (profile) {
          final badgeColor = _parseHexColor(profile.profileBadgeColor, const Color(0xFF615DFA));
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileDetailProvider(widget.username));
              await _fetchStatuses(1, isRefresh: true);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1. Cover Image & Avatar Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cover Image
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(profile.cover),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      
                      // Avatar overlapping cover
                      Positioned(
                        bottom: 10,
                        child: HexagonAvatar(
                          avatarUrl: profile.avatar,
                          size: 116.0,
                          borderColor: badgeColor,
                          borderWidth: 4.0,
                          isOnline: profile.online,
                          isVerified: profile.verified,
                          verifiedSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),

                  // 2. User Names & Handles
                  Text(
                    profile.name.isNotEmpty ? profile.name : profile.username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${profile.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  
                  const SizedBox(height: 12),

                  // 3. Premium Subscription Badge
                  if (profile.subscriptionBadge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _parseHexColor(profile.subscriptionBadge!.color, const Color(0xFF615DFA)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _parseHexColor(profile.subscriptionBadge!.color, const Color(0xFF615DFA)).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            profile.subscriptionBadge!.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 4. Social Links floating bar
                  if (profile.socialLinks.values.any((val) => val.isNotEmpty)) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: profile.socialLinks.entries
                              .where((entry) => entry.value.isNotEmpty)
                              .map((entry) => _buildSocialIcon(entry.key, entry.value))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5. Follow / Message Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        if (widget.username == 'me') ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/settings/profile');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                try {
                                  final response = await ApiClient.instance.post('/profile/${widget.username}/follow');
                                  ref.invalidate(profileDetailProvider(widget.username));
                                  final following = response.data?['following'] == true;
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(following
                                          ? 'Followed successfully'
                                          : 'Unfollowed successfully'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('Failed to perform follow action')),
                                  );
                                }
                              },
                              icon: Icon(
                                profile.isFollowing ? Icons.person_remove : Icons.person_add,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(profile.isFollowing ? 'Unfollow' : 'Follow'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: profile.isFollowing
                                    ? const Color(0xFFEF4444) // Red for unfollow
                                    : const Color(0xFF615DFA), // Purple-blue for follow
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chat messaging will be added in the next phase')),
                                );
                              },
                              icon: const Icon(Icons.mail_outline, size: 18),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 6. Statistics Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Followers', profile.followersCount),
                        _buildStatItem('Following', profile.followingCount),
                        _buildStatItem('Posts', profile.postsCount),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 7. Tabs Header
                  TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      setState(() {});
                    },
                    indicatorColor: const Color(0xFF615DFA),
                    labelColor: const Color(0xFF615DFA),
                    unselectedLabelColor: isDark 
                        ? Colors.white.withValues(alpha: 0.6) 
                        : Colors.black.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Timeline'),
                      Tab(text: 'Photos'),
                      Tab(text: 'About'),
                    ],
                  ),

                  // 8. Tab Contents
                  Container(
                    constraints: const BoxConstraints(minHeight: 300),
                    child: [
                      // TIMELINE TAB
                      _isLoadingStatuses
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _statusesError != null
                              ? _buildErrorState(_statusesError!)
                              : _statuses.isEmpty
                                  ? _buildEmptyState('No activities found.')
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _statuses.length + (_isLoadingMoreStatuses ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == _statuses.length) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        }
                                        return PostCard(status: _statuses[index]);
                                      },
                                    ),
                      
                      // PHOTOS TAB
                      _isLoadingStatuses
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _statusesError != null
                              ? _buildErrorState(_statusesError!)
                              : () {
                                  final photoStatuses = _statuses.where((status) {
                                    return status.displayImage != null && status.displayImage!.isNotEmpty ||
                                           status.hasGallery;
                                  }).toList();

                                  if (photoStatuses.isEmpty) {
                                    return _buildEmptyState('No photos uploaded yet.');
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: photoStatuses.length,
                                    itemBuilder: (context, index) {
                                      final status = photoStatuses[index];
                                      final imageUrl = status.hasGallery ? status.gallery.first : status.displayImage!;
                                      return GestureDetector(
                                        onTap: () => context.push('/post', extra: status),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }(),

                      // ABOUT TAB
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bio Card
                            _buildAboutSectionTitle('About Me'),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.03) 
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.05) 
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Text(
                                profile.bio.isNotEmpty ? profile.bio : 'No bio information provided.',
                                style: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // Badges showcase
                            if (profile.badges.isNotEmpty) ...[
                              _buildAboutSectionTitle('Earned Badges'),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: profile.badges.length,
                                itemBuilder: (context, index) {
                                  final badge = profile.badges[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF615DFA).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF615DFA).withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getBadgeIcon(badge.icon),
                                          color: const Color(0xFF615DFA),
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          badge.name,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],


                          ],
                        ),
                      ),
                    ][_tabController.index],
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(profileDetailProvider(widget.username));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAboutSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Text(
          error,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


