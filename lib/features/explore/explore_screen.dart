import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'explore_provider.dart';
import '../profile/profile_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users, posts, products, forums...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.error.isNotEmpty
                    ? Center(child: Text(searchState.error, style: const TextStyle(color: Colors.red)))
                    : searchState.results.isEmpty && _searchController.text.isNotEmpty
                        ? const Center(child: Text('No results found.', style: TextStyle(color: Colors.white54)))
                        : _searchController.text.isEmpty
                            ? _buildDefaultExplore()
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
                                itemCount: searchState.results.length,
                                itemBuilder: (context, index) {
                                  final item = searchState.results[index];
                                  return _buildSearchResultItem(context, item);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultExplore() {
    return ListView(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      children: [
        _buildExploreSection('Trending Topics', Icons.trending_up, Colors.purple, null),
        const SizedBox(height: 24),
        _buildExploreSection('Marketplace Picks', Icons.shopping_bag, Colors.cyan, () => context.push('/store/products')),
        const SizedBox(height: 24),
        _buildExploreSection('Top Forums', Icons.forum, Colors.green, () => context.push('/forums')),
        const SizedBox(height: 24),
        _buildExploreSection('Latest News', Icons.article, Colors.orange, null),
      ],
    );
  }

  Widget _buildExploreSection(String title, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              if (onTap != null) ...[
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ]
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: Text('Search to discover content', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, Map<String, dynamic> item) {
    IconData icon;
    Color iconColor;

    switch (item['type']) {
      case 'user':
        icon = Icons.person;
        iconColor = Colors.blue;
        break;
      case 'product':
        icon = Icons.shopping_bag;
        iconColor = Colors.green;
        break;
      case 'forum':
        icon = Icons.forum;
        iconColor = Colors.purple;
        break;
      case 'post':
        icon = Icons.article;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.search;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: item['img'] != null
          ? CircleAvatar(backgroundImage: NetworkImage(item['img']))
          : CircleAvatar(backgroundColor: iconColor.withOpacity(0.2), child: Icon(icon, color: iconColor)),
      title: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: item['subtitle'] != null ? Text(item['subtitle'], style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
      onTap: () {
        // Handle navigation based on type
        if (item['type'] == 'user') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(username: item['identifier'])));
        } else if (item['type'] == 'product') {
          context.push('/store/products/${item['id']}');
        } else if (item['type'] == 'forum') {
          context.push('/forums/topics/${item['id']}');
        } else if (item['type'] == 'post') {
          // Navigate to PostDetailScreen
        }
      },
    );
  }
}
