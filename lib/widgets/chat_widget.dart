import 'package:flutter/material.dart';
import 'chat/chat_widget.dart' as chat_module;

/// 该文件已经拆分成多个小组件文件，请改用 lib/widgets/chat 目录下的组件
///
/// @deprecated 这个组件已经被拆分到子组件中，为了向后兼容而保留
class ChatWidget extends StatelessWidget {
  final String meetingId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool isReadOnly;

  const ChatWidget({
    required this.meetingId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 直接使用新的组件实现
    return chat_module.ChatWidget(
      meetingId: meetingId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      isReadOnly: isReadOnly,
    );
  }
}
