import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAvatarTap;
  
  const CustomAppBar({required this.onAvatarTap, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('会议管理系统'),
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
        ),
        onPressed: onAvatarTap, // 使用传入的回调
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}