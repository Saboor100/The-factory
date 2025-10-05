import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'create_post_bottom_sheet.dart';
import '../home_screen.dart';

class CreatePostCard extends StatelessWidget {
  final String? avatarUrl;
  const CreatePostCard({Key? key, this.avatarUrl}) : super(key: key);

  void _showCreatePostDialog(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostBottomSheet(avatarUrl: avatarUrl),
    );

    if (result == true && context.mounted) {
      final feedScreenState =
          context.findAncestorStateOfType<FactoryFeedScreenState>();
      feedScreenState?.loadFeedData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreatePostDialog(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF232723),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildProfileAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "What's on your mind?",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15.5,
                ),
              ),
            ),
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFFB8FF00),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (avatarUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder:
            (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider, radius: 20),
        placeholder:
            (context, url) => const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF3A3A3A),
              child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
            ),
        errorWidget:
            (context, url, error) => const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF3A3A3A),
              child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
            ),
      );
    }

    // No avatar - show default icon
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF3A3A3A),
      child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
    );
  }
}
