import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import 'user_search_widget.dart';
import '../providers/user_providers.dart';

/// 显示用户选择对话框
Future<List<String>?> showUserSelectionDialog({
  required BuildContext context,
  required List<String> initialSelectedUserIds,
}) async {
  // 保存context引用，避免跨越异步间隙使用BuildContext
  final contextCaptured = context;

  // 创建临时选择状态以便在弹窗中使用
  // 过滤掉userId为0的系统用户
  final tempSelectedUserIds = List<String>.from(initialSelectedUserIds)
    ..removeWhere((id) => id == '0');

  // 获取provider容器
  final container = ProviderScope.containerOf(contextCaptured);

  // 重置Riverpod状态
  container.read(userSelectProvider.notifier).updateAll(tempSelectedUserIds);

  // 标记对话框是否已经初始化
  bool isInitialized = false;

  final bool? result = await showDialog<bool>(
    context: contextCaptured,
    barrierDismissible: false, // 防止误触背景关闭对话框
    builder: (BuildContext dialogContext) {
      // 获取屏幕尺寸
      final Size screenSize = MediaQuery.of(dialogContext).size;
      final double maxDialogWidth = math.min(screenSize.width * 0.85, 450.0);
      final double maxDialogHeight = math.min(screenSize.height * 0.75, 600.0);

      return StatefulBuilder(
        builder: (context, setState) {
          // 在对话框首次构建后立即加载所有用户
          if (!isInitialized) {
            isInitialized = true;
            // 延迟执行以确保组件已完全构建
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 立即执行搜索
              SearchTriggerNotification('').dispatch(context);
            });
          }

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: maxDialogWidth,
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16), // 更大的圆角
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                // 使用SingleChildScrollView防止整个弹窗溢出
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16), // 匹配外部圆角
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题栏 - 固定在顶部，使用更现代的样式
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(13),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(128),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '选择可参与的用户',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // 关闭按钮
                            IconButton(
                              icon: const Icon(Icons.close, size: 22),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.withAlpha(26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 内容区域 - 使用Expanded确保内容区域自适应高度，并使用SingleChildScrollView防止内容溢出
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                            child: UserSearchWidget(
                              initialSelectedUserIds: tempSelectedUserIds,
                              onSelectedUsersChanged: (_) {
                                // 选择变化直接反映在provider中，不需要额外处理
                                // 强制刷新对话框状态以更新底部按钮
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ),

                      // 按钮区域 - 固定在底部，使用更现代的样式
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 5,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 清除选择按钮 - 使用ConstrainedBox控制最大宽度防止溢出
                            Consumer(
                              builder: (context, ref, _) {
                                final selectedUserIds = ref.watch(
                                  userSelectProvider,
                                );
                                final currentUserIdAsync = ref.watch(
                                  currentLoggedInUserIdProvider,
                                );

                                return currentUserIdAsync.when(
                                  data: (currentUserId) {
                                    // 计算真实选中用户数量（不包括当前用户）
                                    final actualSelectedCount =
                                        selectedUserIds
                                            .where((id) => id != currentUserId)
                                            .length;

                                    // 使用ConstrainedBox限制按钮最大宽度，防止文本过长溢出
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            maxDialogWidth *
                                            0.4, // 限制最大宽度为对话框的40%
                                      ),
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.clear, size: 16),
                                        label:
                                            actualSelectedCount > 0
                                                ? Text(
                                                  '清空选择 ($actualSelectedCount)',
                                                )
                                                : const Text('清空选择'),
                                        onPressed:
                                            actualSelectedCount > 0
                                                ? () {
                                                  // 保留当前用户ID（如果在列表中）
                                                  final List<String>
                                                  newSelection =
                                                      selectedUserIds.contains(
                                                            currentUserId,
                                                          )
                                                          ? [currentUserId]
                                                          : [];

                                                  ref
                                                      .read(
                                                        userSelectProvider
                                                            .notifier,
                                                      )
                                                      .updateAll(newSelection);

                                                  // 强制刷新对话框
                                                  setState(() {});
                                                }
                                                : null,
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    );
                                  },
                                  loading:
                                      () => const SizedBox(
                                        width: 100,
                                        child: OutlinedButton(
                                          onPressed: null,
                                          child: Text('清空选择'),
                                        ),
                                      ),
                                  error:
                                      (_, __) => const SizedBox(
                                        width: 100,
                                        child: OutlinedButton(
                                          onPressed: null,
                                          child: Text('清空选择'),
                                        ),
                                      ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('确认选择'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // 如果确认了选择，返回选择的用户ID
  if (result == true) {
    // 使用之前保存的container引用，避免再次使用BuildContext
    return container.read(userSelectProvider);
  }

  // 取消选择返回null
  return null;
}
