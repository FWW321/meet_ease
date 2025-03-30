import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/chat_message.dart';
import '../providers/chat_providers.dart';

/// 优化的聊天组件，作为会议中的主要内容
class ChatWidget extends HookConsumerWidget {
  final String meetingId;
  final String userId;
  final String userName;
  final String? userAvatar;

  const ChatWidget({
    required this.meetingId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 消息列表
    final messagesAsync = ref.watch(meetingMessagesProvider(meetingId));

    // 是否显示日期分隔
    final showDateSeparator = useState(true);

    // 是否在录音
    final isRecording = useState(false);

    // 录音时长（模拟）
    final recordDuration = useState(0);

    // 计时器
    final recordTimer = useState<Timer?>(null);

    // 文本控制器
    final textController = useTextEditingController();

    // 滚动控制器
    final scrollController = useScrollController();

    // 是否显示表情选择器
    final showEmojiPicker = useState(false);

    // 聚焦节点
    final focusNode = useFocusNode();

    // 监听焦点变化，隐藏表情选择器
    useEffect(() {
      void onFocusChange() {
        if (focusNode.hasFocus) {
          showEmojiPicker.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () {
        focusNode.removeListener(onFocusChange);
      };
    }, [focusNode]);

    // 滚动到底部
    void scrollToBottom() {
      Timer(const Duration(milliseconds: 300), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // 处理发送文本消息
    Future<void> sendTextMessage() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;

      try {
        await ref.read(
          sendTextMessageProvider({
            'meetingId': meetingId,
            'senderId': userId,
            'senderName': userName,
            'content': text,
            'senderAvatar': userAvatar,
          }).future,
        );

        textController.clear();

        // 滚动到底部
        scrollToBottom();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('发送消息失败: ${e.toString()}')));
        }
      }
    }

    // 停止录音并发送语音消息
    Future<void> stopRecording() async {
      if (!isRecording.value) return;

      isRecording.value = false;
      recordTimer.value?.cancel();
      recordTimer.value = null;

      // 如果录音时长过短，不发送
      if (recordDuration.value < 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('录音时间过短')));
        }
        return;
      }

      try {
        await ref.read(
          sendVoiceMessageProvider({
            'meetingId': meetingId,
            'senderId': userId,
            'senderName': userName,
            'voiceUrl': 'https://example.com/voice/message_mock.mp3',
            'voiceDuration': Duration(seconds: recordDuration.value),
            'senderAvatar': userAvatar,
          }).future,
        );

        // 滚动到底部
        scrollToBottom();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('发送语音消息失败: ${e.toString()}')));
        }
      }
    }

    // 开始录音（模拟）
    void startRecording() {
      isRecording.value = true;
      recordDuration.value = 0;

      // 开始计时
      recordTimer.value = Timer.periodic(const Duration(seconds: 1), (_) {
        recordDuration.value += 1;

        // 最大录音时长限制（60秒）
        if (recordDuration.value >= 60) {
          stopRecording();
        }
      });
    }

    // 取消录音
    void cancelRecording() {
      if (!isRecording.value) return;

      isRecording.value = false;
      recordTimer.value?.cancel();
      recordTimer.value = null;
    }

    // 标记消息为已读
    void markMessageAsRead(String messageId) {
      ref.read(
        markMessageAsReadProvider({'messageId': messageId, 'userId': userId}),
      );
    }

    // 添加表情到输入框
    void insertEmoji(String emoji) {
      final text = textController.text;
      final selection = textController.selection;
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + emoji.length,
        ),
      );
    }

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('暂无消息，开始聊天吧！', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              // 标记所有消息为已读
              for (final message in messages) {
                if (!message.readByUserIds.contains(userId)) {
                  markMessageAsRead(message.id);
                }
              }

              // 自动滚动到底部（仅首次加载）
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients &&
                    !scrollController.position.isScrollingNotifier.value) {
                  scrollToBottom();
                }
              });

              return Stack(
                children: [
                  ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final previousMessage =
                          index > 0 ? messages[index - 1] : null;

                      // 是否需要显示日期分隔
                      final showDate =
                          showDateSeparator.value &&
                          (previousMessage == null ||
                              !_isSameDay(
                                previousMessage.timestamp,
                                message.timestamp,
                              ));

                      // 是否需要显示头像和昵称（同一用户连续发言只显示一次）
                      final showSenderInfo =
                          previousMessage == null ||
                          previousMessage.senderId != message.senderId ||
                          message.timestamp
                                  .difference(previousMessage.timestamp)
                                  .inMinutes >
                              5;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 日期分隔
                          if (showDate) _buildDateSeparator(message.timestamp),

                          // 消息项
                          _buildMessageItem(
                            context,
                            message,
                            showSenderInfo: showSenderInfo,
                          ),
                        ],
                      );
                    },
                  ),

                  // 回到底部按钮
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: AnimatedBuilder(
                      animation: scrollController,
                      builder: (context, _) {
                        if (!scrollController.hasClients) {
                          return const SizedBox.shrink();
                        }

                        // 只有滚动位置距离底部超过200才显示按钮
                        final showButton =
                            scrollController.position.pixels <
                            scrollController.position.maxScrollExtent - 200;

                        return AnimatedOpacity(
                          opacity: showButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child:
                              showButton
                                  ? FloatingActionButton.small(
                                    onPressed: scrollToBottom,
                                    backgroundColor: Colors.white,
                                    elevation: 4,
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => Center(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '获取消息失败\n',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        TextSpan(text: error.toString()),
                      ],
                    ),
                  ),
                ),
          ),
        ),

        // 录音状态指示器
        if (isRecording.value)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                // 动画闪烁的麦克风图标
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Icon(
                      Icons.mic,
                      color: Color.fromARGB(
                        (value * 255).round(),
                        Colors.red.r.toInt(),
                        Colors.red.g.toInt(),
                        Colors.red.b.toInt(),
                      ),
                      size: 24,
                    );
                  },
                ),
                const SizedBox(width: 8),

                // 录音时长
                Text(
                  '录音中 ${_formatDuration(Duration(seconds: recordDuration.value))}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const Spacer(),

                // 取消录音按钮
                TextButton(onPressed: cancelRecording, child: const Text('取消')),

                // 发送录音按钮
                ElevatedButton(
                  onPressed: stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('发送'),
                ),
              ],
            ),
          ),

        // 表情选择器
        if (showEmojiPicker.value)
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _commonEmojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => insertEmoji(_commonEmojis[index]),
                  child: Center(
                    child: Text(
                      _commonEmojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),

        // 输入框
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                offset: const Offset(0, -1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              // 表情按钮
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: showEmojiPicker.value ? Colors.blue : null,
                ),
                onPressed: () {
                  focusNode.unfocus();
                  showEmojiPicker.value = !showEmojiPicker.value;
                },
                tooltip: '表情',
              ),

              // 语音/文本输入切换按钮
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: isRecording.value ? stopRecording : startRecording,
                color: isRecording.value ? Colors.red : null,
                tooltip: isRecording.value ? '停止录音' : '开始录音',
              ),

              // 文本输入框
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: !isRecording.value,
                  decoration: InputDecoration(
                    hintText: isRecording.value ? '正在录音...' : '输入消息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  onSubmitted:
                      isRecording.value ? null : (_) => sendTextMessage(),
                ),
              ),

              // 发送按钮
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.blue,
                onPressed: isRecording.value ? null : sendTextMessage,
                tooltip: '发送',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建消息项
  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message, {
    bool showSenderInfo = true,
  }) {
    final isMyMessage = message.senderId == userId;
    final timeFormat = DateFormat('HH:mm');
    final time = timeFormat.format(message.timestamp);

    // 自定义气泡颜色
    final bubbleColor =
        isMyMessage ? Colors.blue.shade100 : Colors.grey.shade100;

    // 文本方向
    final direction =
        isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: direction,
        children: [
          // 发送者信息（仅对他人消息显示）
          if (showSenderInfo && !isMyMessage)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          // 消息内容
          Row(
            mainAxisAlignment:
                isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧头像（仅对他人消息显示）
              if (!isMyMessage)
                if (showSenderInfo)
                  _buildAvatar(message)
                else
                  const SizedBox(width: 40),

              const SizedBox(width: 8),

              // 消息气泡
              Column(
                crossAxisAlignment: direction,
                children: [
                  _buildMessageBubble(message, bubbleColor),

                  // 时间显示
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      right: isMyMessage ? 0 : 4,
                      left: isMyMessage ? 4 : 0,
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // 右侧头像（仅对自己的消息显示）
              if (isMyMessage)
                if (showSenderInfo)
                  _buildAvatar(message)
                else
                  const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar(ChatMessage message) {
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

  // 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message, Color bubbleColor) {
    if (message.isTextMessage) {
      // 文本消息
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(message.content),
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

  // 构建日期分隔
  Widget _buildDateSeparator(DateTime timestamp) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final date = dateFormat.format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  // 判断两个日期是否是同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// 常用表情列表
const _commonEmojis = ['😊', '😂', '👍', '❤️', '🔥', '😍', '😘', '😎'];
