import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../services/service_providers.dart';

/// 优化的聊天组件，作为会议中的主要内容
class ChatWidget extends HookConsumerWidget {
  final String meetingId;
  final String userId; // 传入的userId可能不准确，我们将从UserService获取真实的当前用户ID
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
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前登录用户ID（从用户服务中）
    final currentUserId = useState<String?>(null);

    // 使用useEffect获取当前用户ID
    useEffect(() {
      Future<void> fetchCurrentUserId() async {
        try {
          final userService = ref.read(userServiceProvider);
          final user = await userService.getCurrentUser();
          if (user != null) {
            currentUserId.value = user.id;
          } else {
            currentUserId.value = userId; // 回退到传入的userId
          }
        } catch (e) {
          currentUserId.value = userId; // 错误情况下回退到传入的userId
        }
      }

      fetchCurrentUserId();
      return null;
    }, []);

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

    // 当前选中的表情分类
    final selectedEmojiCategory = useState<String>('笑脸');

    // 聚焦节点
    final focusNode = useFocusNode();

    // 是否有键盘显示
    final isKeyboardVisible = useState(false);

    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 更新键盘可见状态
    useEffect(() {
      isKeyboardVisible.value = keyboardHeight > 0;
      return null;
    }, [keyboardHeight]);

    // 是否正在加载历史消息
    final isLoadingHistory = useState(false);

    // 使用useEffect在组件第一次加载时加载历史消息
    useEffect(() {
      // 强制刷新消息列表
      ref.invalidate(meetingMessagesProvider(meetingId));
      return null;
    }, []);

    // 监听焦点变化
    useEffect(() {
      void onFocusChange() {
        // 当输入框获得焦点时，隐藏表情选择器
        // 确保键盘和表情选择器不会同时显示
        if (focusNode.hasFocus) {
          showEmojiPicker.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () {
        focusNode.removeListener(onFocusChange);
      };
    }, [focusNode]);

    // 确保输入框在初始化后正确显示光标
    useEffect(() {
      // 延迟一下再设置焦点，避免与其他UI操作冲突
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isReadOnly && !isRecording.value && context.mounted) {
          focusNode.requestFocus();
        }
      });
      return null;
    }, []);

    // 处理表情按钮点击
    void handleEmojiButtonClick() {
      // 如果表情选择器已经显示，隐藏它并显示键盘
      if (showEmojiPicker.value) {
        showEmojiPicker.value = false;
        // 短暂延迟后请求焦点，以确保UI状态更新
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            focusNode.requestFocus(); // 显示键盘
          }
        });
      } else {
        // 如果表情选择器未显示，隐藏键盘并显示表情选择器
        showEmojiPicker.value = true;
        focusNode.unfocus(); // 隐藏键盘
      }
    }

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

        // 刷新聊天消息列表
        ref.invalidate(meetingMessagesProvider(meetingId));
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
      // 确保选中文本的开始和结束位置有效
      final selection =
          textController.selection.isValid
              ? textController.selection
              : TextSelection.collapsed(offset: textController.text.length);

      final text = textController.text;
      final newText = text.replaceRange(selection.start, selection.end, emoji);

      // 更新文本和光标位置
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + emoji.length,
        ),
      );

      // 确保输入框获得焦点并显示光标
      // 为保持表情选择器显示，这里不要请求焦点
      // focusNode.requestFocus();
    }

    // 构建表情选择器
    Widget buildEmojiPicker() {
      // 获取当前选中分类的表情
      final emojis = _emojisByCategory[selectedEmojiCategory.value] ?? [];

      // 使用固定高度模拟键盘高度
      const emojiKeyboardHeight = 250.0;

      return Container(
        height: emojiKeyboardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              offset: const Offset(0, -3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // 表情网格
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => insertEmoji(emojis[index]),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 分类选项卡 - 移到底部
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children:
                    _emojisByCategory.keys.map((category) {
                      final isSelected =
                          selectedEmojiCategory.value == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: InkWell(
                            onTap: () => selectedEmojiCategory.value = category,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.blue.shade100
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade700,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
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

              return RefreshIndicator(
                onRefresh: () async {
                  // 下拉刷新重新加载消息
                  isLoadingHistory.value = true;
                  try {
                    ref.invalidate(meetingMessagesProvider(meetingId));
                    await ref.read(meetingMessagesProvider(meetingId).future);
                  } finally {
                    isLoadingHistory.value = false;
                  }
                },
                child: Stack(
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
                                  message.timestamp,
                                  previousMessage.timestamp,
                                ));

                        // 是否为当前用户发送的消息 - 使用真实的当前用户ID
                        final realCurrentUserId = currentUserId.value ?? userId;
                        final isSentByMe =
                            message.senderId == realCurrentUserId;

                        return Column(
                          children: [
                            // 显示日期分隔线
                            if (showDate)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 16.0,
                                ),
                                child: _buildDateSeparator(message.timestamp),
                              ),

                            // 消息气泡
                            _buildMessageBubble(
                              context,
                              message,
                              isSentByMe,
                              realCurrentUserId,
                            ),
                          ],
                        );
                      },
                    ),

                    // 加载历史消息指示器
                    if (isLoadingHistory.value)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          '加载消息失败，请检查网络连接后重试',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          error.toString().replaceAll('Exception:', ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(meetingMessagesProvider(meetingId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新加载'),
                      ),
                    ],
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

        // 输入框
        if (!isReadOnly)
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
                  onPressed: handleEmojiButtonClick,
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
                    onTap: () {
                      // 确保点击输入框时关闭表情选择器
                      if (showEmojiPicker.value) {
                        showEmojiPicker.value = false;
                      }
                    },
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

        // 表情选择器 - 当键盘不可见且启用表情选择器时显示
        if (showEmojiPicker.value && !isKeyboardVisible.value)
          buildEmojiPicker(),

        // 只读模式提示
        if (isReadOnly)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text(
              '此会议已结束，无法发送新消息',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  // 构建消息气泡(用于消息列表)
  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    bool isSentByMe,
    String currentUserId,
  ) {
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
          if (!isSentByMe) _buildAvatar(message),

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
              _buildMessageContent(message, bubbleColor),

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
          if (isSentByMe) _buildAvatar(message),
        ],
      ),
    );
  }

  // 构建消息内容
  Widget _buildMessageContent(ChatMessage message, Color bubbleColor) {
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

// 常用表情列表（按分类）
const Map<String, List<String>> _emojisByCategory = {
  '笑脸': [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
  ],
  '手势': [
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '👋',
    '🤚',
    '🖐️',
    '✋',
    '🖖',
    '👏',
    '🙌',
  ],
  '心形': [
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '💖',
    '💗',
    '💓',
    '💞',
    '💕',
    '❣️',
    '💔',
    '💘',
    '💝',
    '💟',
    '☮️',
  ],
  '动物': [
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐸',
    '🐵',
    '🙈',
    '🙉',
    '🙊',
    '🐒',
    '🦆',
  ],
  '食物': [
    '🍏',
    '🍎',
    '🍐',
    '🍊',
    '🍋',
    '🍌',
    '🍉',
    '🍇',
    '🍓',
    '🍈',
    '🍒',
    '🍑',
    '🥭',
    '🍍',
    '🥥',
    '🥝',
    '🍅',
    '🍆',
    '🥑',
    '🌮',
  ],
};
