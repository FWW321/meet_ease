import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

/// 系统消息组件，用于显示系统通知
class ChatSystemMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatSystemMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    // 确定消息类型和图标
    IconData? messageIcon;
    Color iconColor = Colors.grey.shade700;
    Color backgroundColor = Colors.grey.shade200;

    // 根据消息内容确定图标和颜色
    final content = message.content.toLowerCase();
    if (content.contains('加入了会议')) {
      messageIcon = Icons.login;
      iconColor = Colors.green;
      backgroundColor = Colors.green.shade50;
    } else if (content.contains('离开了会议')) {
      messageIcon = Icons.logout;
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
    } else {
      messageIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (messageIcon != null) ...[
            Icon(messageIcon, size: 14, color: iconColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
