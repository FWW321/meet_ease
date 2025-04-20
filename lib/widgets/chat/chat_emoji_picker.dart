import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 表情选择器组件
class ChatEmojiPicker extends HookWidget {
  /// 表情数据
  final Map<String, List<String>> emojisData;

  /// 当前选中的表情分类
  final ValueNotifier<String> selectedCategory;

  /// 选择表情的回调
  final Function(String) onEmojiSelected;

  /// 表情选择器的最大高度
  final double maxHeight;

  const ChatEmojiPicker({
    required this.emojisData,
    required this.selectedCategory,
    required this.onEmojiSelected,
    required this.maxHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前选中分类的表情
    final currentEmojis = emojisData[selectedCategory.value] ?? [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      constraints: BoxConstraints(maxHeight: maxHeight),
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 表情网格 - 添加缓存以提高性能
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(8),
                // 使用缓存提高滚动性能
                cacheExtent: 500,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: currentEmojis.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: InkWell(
                      onTap: () => onEmojiSelected(currentEmojis[index]),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          currentEmojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 分类选项卡
            _buildCategoryTabs(),
          ],
        ),
      ),
    );
  }

  /// 构建表情分类选项卡
  Widget _buildCategoryTabs() {
    return RepaintBoundary(
      child: Container(
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
          // 避免频繁重建
          cacheExtent: 1000,
          children:
              emojisData.keys.map((category) {
                final isSelected = selectedCategory.value == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: InkWell(
                      onTap: () => selectedCategory.value = category,
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
                                isSelected ? Colors.blue : Colors.grey.shade700,
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
    );
  }
}
