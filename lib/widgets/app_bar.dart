import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAvatarTap;
  final String? avatarUrl;

  const CustomAppBar({required this.onAvatarTap, this.avatarUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('会议管理系统'),
      leading: IconButton(
        icon: _buildAvatar(),
        onPressed: onAvatarTap, // 使用传入的回调
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.blueGrey,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child:
          avatarUrl == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
