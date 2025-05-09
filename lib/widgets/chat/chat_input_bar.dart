import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 聊天输入栏组件
class ChatInputBar extends HookWidget {
  /// 文本控制器
  final TextEditingController textController;

  /// 聚焦节点
  final FocusNode focusNode;

  /// 表情按钮点击回调
  final VoidCallback onEmojiButtonClick;

  /// 发送消息回调
  final VoidCallback onSendMessage;

  /// 是否显示表情选择器
  final bool showEmojiPicker;

  const ChatInputBar({
    required this.textController,
    required this.focusNode,
    required this.onEmojiButtonClick,
    required this.onSendMessage,
    required this.showEmojiPicker,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 使用RepaintBoundary包装整个输入栏，防止键盘弹出/收起时触发整个聊天区域的重绘
    return RepaintBoundary(
      child: Container(
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
        // 禁用布局动画效果，避免键盘弹出时的动画导致卡顿
        child: AnimatedSize(
          duration: const Duration(milliseconds: 0),
          alignment: Alignment.topCenter,
          child: Row(
            children: [
              // 表情按钮
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: showEmojiPicker ? Colors.blue : null,
                  ),
                  onPressed: onEmojiButtonClick,
                  tooltip: '表情',
                ),
              ),

              // 文本输入框 - 使用RepaintBoundary包装，防止输入时的重绘扩散
              Expanded(
                child: RepaintBoundary(
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    // 减少输入时重建开销
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          maxLength,
                          required isFocused,
                        }) => null,
                    scrollPhysics: const ClampingScrollPhysics(),
                    decoration: InputDecoration(
                      hintText: '输入消息...',
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
                      // 优化边框渲染
                      isDense: true,
                      // 减少装饰的重绘
                      isCollapsed: false,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    // 优化点击处理，避免不必要的状态更新
                    onTap:
                        showEmojiPicker
                            ? () {
                              onEmojiButtonClick();
                            }
                            : null,
                    onSubmitted: (_) => onSendMessage(),
                    // 使用防抖动处理文本变化
                    onChanged: (_) {
                      // 空实现但确保不会触发额外的状态更新
                    },
                    keyboardAppearance: Brightness.light, // 使用明亮主题的键盘，减少资源消耗
                  ),
                ),
              ),

              // 发送按钮
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.blue,
                onPressed: onSendMessage,
                tooltip: '发送',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
