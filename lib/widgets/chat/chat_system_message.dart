import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

/// 系统消息组件，用于显示系统通知
class ChatSystemMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatSystemMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.content,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        textAlign: TextAlign.center,
      ),
    );
  }
}
