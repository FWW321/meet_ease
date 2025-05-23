import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_providers.dart';
import '../../services/service_providers.dart';
import 'chat_message_list.dart';
import 'chat_input_bar.dart';
import 'chat_emoji_picker.dart';

/// 优化的聊天组件，作为会议中的主要内容
class ChatWidget extends HookConsumerWidget {
  final String meetingId;
  final String userId; // 传入的userId可能不准确，我们将从UserService获取真实的当前用户ID
  final String userName;
  final String? userAvatar;
  final bool isReadOnly;

  // 添加未读消息计数状态
  static final unreadCountProvider = StateProvider<int>((ref) => 0);

  const ChatWidget({
    required this.meetingId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.isReadOnly = false,
    super.key,
  });

  // 添加更新未读消息计数的方法
  static void updateUnreadCount(WidgetRef ref, int count) {
    ref.read(unreadCountProvider.notifier).state = count;
  }

  // 添加重置未读消息计数的方法
  static void resetUnreadCount(WidgetRef ref) {
    ref.read(unreadCountProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前登录用户ID（从用户服务中）
    final currentUserId = useState<String?>(null);

    // 提前预加载消息列表，避免懒加载导致的卡顿
    useEffect(() {
      // 使用微任务确保不阻塞UI
      Future.microtask(() async {
        // 预加载消息数据
        await ref.read(meetingMessagesProvider(meetingId).future);
        // 预加载表情数据
        await ref.read(emojisProvider.future);
      });
      return null;
    }, const []);

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
      // 获取WebSocket消息流
      final chatService = ref.read(chatServiceProvider);
      final messageStream = chatService.getMessageStream(meetingId);

      // 订阅消息流
      final subscription = messageStream.listen(
        (message) {
          try {
            debugPrint('ChatWidget接收到WebSocket消息: $message');

            // 将消息添加到本地消息列表
            localMessages.value = [...localMessages.value, message];

            // 滚动到底部显示新消息
            scrollToBottom();
          } catch (e) {
            debugPrint('ChatWidget处理WebSocket消息失败: $e');
          }
        },
        onError: (error) {
          debugPrint('ChatWidget WebSocket消息流错误: $error');
        },
      );

      // 清理订阅
      return () {
        subscription.cancel();
      };
    }, [meetingId]);

    // 消息列表
    final messagesAsync = ref.watch(meetingMessagesProvider(meetingId));

    // 是否显示日期分隔
    final showDateSeparator = useState(true);

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

    // 简化键盘状态检测，不再使用定时器和节流
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // 记录键盘打开状态，用于表情选择器关闭时恢复
    final wasKeyboardVisible = useRef<bool>(false);

    // 添加键盘优化器
    useEffect(() {
      // 设置键盘响应模式以优化性能
      SystemChannels.textInput.invokeMethod('TextInput.setImeTransferMode', {
        'mode': 'direct',
      });

      return null;
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
      if (!isReadOnly && context.mounted) {
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
        // 关闭表情选择器
        showEmojiPicker.value = false;

        // 如果之前键盘是打开的，则需要重新打开键盘
        if (wasKeyboardVisible.value) {
          // 延迟200ms再显示键盘，等待表情选择器完全消失，避免界面跳动
          Future.delayed(const Duration(milliseconds: 200), () {
            if (context.mounted) {
              focusNode.requestFocus();
            }
          });
        }
      } else {
        // 打开表情选择器前记录当前键盘状态
        wasKeyboardVisible.value = isKeyboardVisible;

        // 先取消焦点，隐藏键盘
        focusNode.unfocus();

        // 延迟到键盘完全收起后再显示表情选择器，避免界面跳动
        Future.delayed(const Duration(milliseconds: 100), () {
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
        // 确保有用户ID
        final userId = currentUserId.value;
        if (userId == null || userId.isEmpty) {
          throw Exception('用户ID不能为空');
        }

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

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: RepaintBoundary(
            child: messagesAsync.when(
              data: (messages) {
                // 合并历史消息和WebSocket实时消息
                final combinedMessages = [...messages, ...localMessages.value];

                // 过滤掉系统消息、WebRTC信令消息以及头像会显示为"?"的消息
                final filteredMessages =
                    combinedMessages.where((message) {
                      // 如果是系统消息，检查是否包含WebRTC信令
                      if (message.isSystemMessage) {
                        return false;
                      }

                      // 检查是否是WebRTC信令消息（通过消息内容判断）
                      try {
                        final content = message.content;
                        if (content.startsWith('{') && content.endsWith('}')) {
                          final jsonData = jsonDecode(content);
                          // 如果消息类型是WEBRTC_SIGNAL，则过滤掉
                          if (jsonData['messageType'] == 'WEBRTC_SIGNAL') {
                            return false;
                          }
                        }
                      } catch (_) {
                        // 解析失败说明不是JSON格式，不是WebRTC信令
                      }

                      // 过滤掉头像为空且名称为空的消息
                      return !(message.senderAvatar == null &&
                          message.senderName.isEmpty);
                    }).toList();

                // 按时间排序
                filteredMessages.sort(
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
                  messages: filteredMessages,
                  currentUserId: currentUserId.value ?? userId,
                  scrollController: scrollController,
                  showDateSeparator: showDateSeparator.value,
                  isLoadingHistory: isLoadingHistory.value,
                  onRefresh: handleRefresh,
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
        ),

        // 底部输入区域使用一个RepaintBoundary包装，防止键盘弹出/收起时重绘上面的内容
        RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 输入框 - 使用拆分出的组件
              if (!isReadOnly)
                ChatInputBar(
                  textController: textController,
                  focusNode: focusNode,
                  onEmojiButtonClick: handleEmojiButtonClick,
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
                    showEmojiPicker.value && !isKeyboardVisible
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    '此会议已结束，无法发送新消息',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
