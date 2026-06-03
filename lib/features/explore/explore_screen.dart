import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16, 
          right: 16, 
          top: 16, 
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _buildExploreSection('Trending Topics', Icons.trending_up, Colors.purple),
          const SizedBox(height: 24),
          _buildExploreSection('Marketplace Picks', Icons.shopping_bag, Colors.cyan),
          const SizedBox(height: 24),
          _buildExploreSection('Top Forums', Icons.forum, Colors.green),
          const SizedBox(height: 24),
          _buildExploreSection('Latest News', Icons.article, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildExploreSection(String title, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Center(
            child: Text('Content Placeholder', style: TextStyle(color: Colors.white54)),
          ),
        ),
      ],
    );
  }
}
