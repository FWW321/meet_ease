import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

/// 系统消息组件，用于显示系统通知
class ChatSystemMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatSystemMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    // 解析新的消息格式
    String username = "";
    String action = "";

    // 尝试解析消息格式: userId:xxx, username:xxx, action:xxx
    final content = message.content;
    final parts = content.split(', ');
    for (final part in parts) {
      if (part.startsWith('username:')) {
        username = part.substring('username:'.length);
      } else if (part.startsWith('action:')) {
        action = part.substring('action:'.length);
      }
    }

    // 确定消息类型和图标
    IconData? messageIcon;
    Color iconColor = Colors.grey.shade700;
    Color backgroundColor = Colors.grey.shade200;

    // 格式化显示的消息文本
    String displayMessage = "";

    // 根据动作类型确定图标和颜色
    if (action == '加入会议') {
      messageIcon = Icons.login;
      iconColor = Colors.green;
      backgroundColor = Colors.green.shade50;
      displayMessage = "$username 加入了会议";
    } else if (action == '离开会议') {
      messageIcon = Icons.logout;
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
      displayMessage = "$username 离开了会议";
    } else {
      messageIcon = Icons.info_outline;
      displayMessage = content; // 如果不是已知格式，显示原始消息
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
              displayMessage,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
