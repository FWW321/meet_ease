import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';

/// 聊天气泡组件，用于显示消息内容
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSentByMe;
  final String currentUserId;

  const ChatMessageBubble({
    required this.message,
    required this.isSentByMe,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final time = timeFormat.format(message.timestamp);

    // 自定义气泡颜色
    final bubbleColor =
        isSentByMe ? Colors.blue.shade100 : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧头像（非当前用户的消息）
          if (!isSentByMe) _buildAvatar(),

          const SizedBox(width: 8),

          // 消息内容
          Column(
            crossAxisAlignment:
                isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 发送者名称（非当前用户的消息）
              if (!isSentByMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              // 消息气泡
              _buildMessageContent(bubbleColor),

              // 消息时间
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // 右侧头像（当前用户的消息）
          if (isSentByMe) _buildAvatar(),
        ],
      ),
    );
  }

  // 构建消息内容
  Widget _buildMessageContent(Color bubbleColor) {
    if (message.isTextMessage) {
      // 文本消息
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(
          message.content,
          style: const TextStyle(
            fontSize: 16.0,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      );
    } else {
      // 语音消息
      return InkWell(
        onTap: () {
          // 播放语音（模拟）
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow),
              const SizedBox(width: 8),
              Text('${message.voiceDuration?.inSeconds ?? 0}秒'),
              const SizedBox(width: 8),
              const Icon(Icons.volume_up, size: 16),
            ],
          ),
        ),
      );
    }
  }

  // 构建头像
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue.shade200,
      backgroundImage:
          message.senderAvatar != null
              ? NetworkImage(message.senderAvatar!) as ImageProvider
              : null,
      child:
          message.senderAvatar == null
              ? Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              )
              : null,
    );
  }
}
