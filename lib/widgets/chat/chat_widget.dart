import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_providers.dart';
import '../../services/service_providers.dart';
import 'chat_message_list.dart';
import 'chat_input_bar.dart';
import 'chat_emoji_picker.dart';
import 'recording_indicator.dart';

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

    // WebSocket消息流
    final webSocketMessages = ref.watch(webSocketMessagesProvider);

    // 本地消息列表（用于保存接收到的WebSocket消息）
    final localMessages = useState<List<ChatMessage>>([]);

    // 滚动控制器
    final scrollController = useScrollController();

    // 滚动到底部的函数
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

    // 处理接收到的WebSocket消息
    useEffect(() {
      webSocketMessages.whenData((message) {
        try {
          final chatMessage = ChatMessage.fromJson(message);
          // 添加到本地消息列表
          localMessages.value = [...localMessages.value, chatMessage];

          // 滚动到底部
          scrollToBottom();
        } catch (e) {
          print('处理WebSocket消息失败: $e');
        }
      });

      return null;
    }, [webSocketMessages]);

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

    // 是否显示表情选择器
    final showEmojiPicker = useState(false);

    // 表情选择器高度 - 屏幕高度的30%，但不超过250
    final emojiPickerHeight = math.min(
      MediaQuery.of(context).size.height * 0.3,
      250.0,
    );

    // 当前选中的表情分类
    final selectedEmojiCategory = useState<String>('笑脸');

    // 表情数据 - 使用异步Provider
    final emojisAsync = ref.watch(emojisProvider);

    // 表情数据
    final emojisData = useState<Map<String, List<String>>>({});

    // 监听表情数据变化
    useEffect(() {
      // 当异步加载完成后更新表情数据
      emojisAsync.whenData((data) {
        if (data.isNotEmpty) {
          emojisData.value = data;

          // 如果当前选择的分类不在新数据中，重置为第一个分类
          if (!data.containsKey(selectedEmojiCategory.value) &&
              data.isNotEmpty) {
            selectedEmojiCategory.value = data.keys.first;
          }
        }
      });

      return null;
    }, [emojisAsync]);

    // 聚焦节点
    final focusNode = useFocusNode();

    // 是否有键盘显示，使用节流防止频繁更新和过度重绘
    final isKeyboardVisible = useState(false);

    // 添加键盘优化器
    useEffect(() {
      // 设置键盘响应模式以优化性能
      SystemChannels.textInput.invokeMethod('TextInput.setImeTransferMode', {
        'mode': 'direct',
      });

      return null;
    }, const []);

    // 优化键盘呼出时UI的流畅性：添加一个防止重复构建的机制
    final keyboardUpdateThrottle = useRef<DateTime>(DateTime.now());

    useEffect(() {
      final keyboardVisibilityTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) {
          final now = DateTime.now();
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final currentKeyboardVisible = keyboardHeight > 0;

          // 至少间隔100ms才更新键盘状态，防止频繁更新导致卡顿
          if (now.difference(keyboardUpdateThrottle.value).inMilliseconds >
                  100 &&
              isKeyboardVisible.value != currentKeyboardVisible) {
            keyboardUpdateThrottle.value = now;
            isKeyboardVisible.value = currentKeyboardVisible;
          }
        },
      );

      return keyboardVisibilityTimer.cancel;
    }, const []);

    // 是否正在加载历史消息
    final isLoadingHistory = useState(false);

    // 使用useEffect在组件第一次加载时加载历史消息
    useEffect(() {
      // 强制刷新消息列表
      ref.invalidate(meetingMessagesProvider(meetingId));
      return null;
    }, []);

    // 监听焦点变化，优化处理方式
    useEffect(() {
      void onFocusChange() {
        // 当输入框获得焦点时，隐藏表情选择器
        if (focusNode.hasFocus && showEmojiPicker.value) {
          showEmojiPicker.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () {
        focusNode.removeListener(onFocusChange);
      };
    }, [focusNode]);

    // 确保输入框在初始化后正确显示光标，移除不必要的延迟
    useEffect(() {
      if (!isReadOnly && !isRecording.value && context.mounted) {
        // 使用microtask确保在UI渲染后执行，避免与其他操作冲突
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
      return null;
    }, []);

    // 处理表情按钮点击，优化切换流畅度
    void handleEmojiButtonClick() {
      if (showEmojiPicker.value) {
        // 先设置状态再请求焦点，避免UI闪烁
        showEmojiPicker.value = false;
        // 使用postFrameCallback确保状态更新后再请求焦点
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            focusNode.requestFocus();
          }
        });
      } else {
        // 先取消焦点再显示表情选择器，避免同时存在
        focusNode.unfocus();
        // 使用postFrameCallback确保UI渲染完成后再更新状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showEmojiPicker.value = true;
          }
        });
      }
    }

    // 处理发送文本消息
    Future<void> sendTextMessage() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;

      try {
        // 使用WebSocket发送消息
        final sendMessage = ref.read(webSocketSendMessageProvider);
        await sendMessage(text);

        // 清除输入框
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
    }

    // 处理下拉刷新
    Future<void> handleRefresh() async {
      isLoadingHistory.value = true;
      try {
        ref.invalidate(meetingMessagesProvider(meetingId));
        await ref.read(meetingMessagesProvider(meetingId).future);
      } finally {
        isLoadingHistory.value = false;
      }
    }

    // 录音按钮点击处理
    void handleVoiceButtonClick() {
      if (isRecording.value) {
        stopRecording();
      } else {
        startRecording();
      }
    }

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              // 合并历史消息和WebSocket实时消息
              final combinedMessages = [...messages, ...localMessages.value];

              // 按时间排序
              combinedMessages.sort(
                (a, b) => a.timestamp.compareTo(b.timestamp),
              );

              // 自动滚动到底部（仅首次加载）
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients &&
                    !scrollController.position.isScrollingNotifier.value) {
                  scrollToBottom();
                }
              });

              // 使用拆分出的消息列表组件
              return ChatMessageList(
                messages: combinedMessages,
                currentUserId: currentUserId.value ?? userId,
                scrollController: scrollController,
                showDateSeparator: showDateSeparator.value,
                isLoadingHistory: isLoadingHistory.value,
                onRefresh: handleRefresh,
                onMessageRead: markMessageAsRead,
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

        // 录音状态指示器 - 使用拆分出的组件
        if (isRecording.value)
          RecordingIndicator(
            recordDuration: recordDuration.value,
            onCancel: cancelRecording,
            onSend: stopRecording,
          ),

        // 输入框 - 使用拆分出的组件
        if (!isReadOnly)
          ChatInputBar(
            textController: textController,
            focusNode: focusNode,
            isRecording: isRecording.value,
            onEmojiButtonClick: handleEmojiButtonClick,
            onVoiceButtonClick: handleVoiceButtonClick,
            onSendMessage: sendTextMessage,
            showEmojiPicker: showEmojiPicker.value,
          ),

        // 表情选择器 - 使用拆分出的组件
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 100),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child:
              showEmojiPicker.value && !isKeyboardVisible.value
                  ? ChatEmojiPicker(
                    emojisData: emojisData.value,
                    selectedCategory: selectedEmojiCategory,
                    onEmojiSelected: insertEmoji,
                    maxHeight: emojiPickerHeight,
                  )
                  : const SizedBox.shrink(),
        ),

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
}
