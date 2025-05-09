import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/chat_message.dart';
import 'chat_message_bubble.dart';
import 'chat_date_separator.dart';

/// 聊天消息列表组件
class ChatMessageList extends ConsumerWidget {
  /// 聊天消息列表
  final List<ChatMessage> messages;

  /// 当前用户ID
  final String currentUserId;

  /// 滚动控制器
  final ScrollController scrollController;

  /// 是否显示日期分隔线
  final bool showDateSeparator;

  /// 是否正在加载历史消息
  final bool isLoadingHistory;

  /// 下拉刷新回调
  final Future<void> Function() onRefresh;

  /// 消息已读标记回调
  final void Function(String) onMessageRead;

  const ChatMessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.showDateSeparator,
    required this.isLoadingHistory,
    required this.onRefresh,
    required this.onMessageRead,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无消息，开始聊天吧！', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 标记所有消息为已读
    for (final message in messages) {
      if (!message.readByUserIds.contains(currentUserId)) {
        onMessageRead(message.id);
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Stack(
        children: [
          ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final previousMessage = index > 0 ? messages[index - 1] : null;

              // 是否需要显示日期分隔
              final showDate =
                  showDateSeparator &&
                  (previousMessage == null ||
                      !ChatDateSeparator.isSameDay(
                        message.timestamp,
                        previousMessage.timestamp,
                      ));

              // 是否为当前用户发送的消息
              final isSentByMe = message.senderId == currentUserId;

              return Column(
                children: [
                  // 显示日期分隔线
                  if (showDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: ChatDateSeparator(timestamp: message.timestamp),
                    ),

                  // 消息气泡
                  ChatMessageBubble(
                    message: message,
                    isSentByMe: isSentByMe,
                    currentUserId: currentUserId,
                  ),
                ],
              );
            },
          ),

          // 加载历史消息指示器
          if (isLoadingHistory)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
