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
    // 使用RepaintBoundary隔离表情选择器的渲染，避免与其他组件重绘相互影响
    return RepaintBoundary(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 表情分类选择器
            _buildCategorySelector(),

            // 分隔线
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),

            // 表情网格
            Expanded(child: _buildEmojiGrid(context)),
          ],
        ),
      ),
    );
  }

  /// 构建表情分类选择器
  Widget _buildCategorySelector() {
    // 表情分类为空，显示加载中
    if (emojisData.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 分类菜单
    return SizedBox(
      height: 40,
      child: RepaintBoundary(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: emojisData.keys.length,
          itemBuilder: (context, index) {
            final category = emojisData.keys.elementAt(index);
            final isSelected = selectedCategory.value == category;

            return InkWell(
              onTap: () => selectedCategory.value = category,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建表情网格
  Widget _buildEmojiGrid(BuildContext context) {
    // 表情分类为空，返回空白
    if (emojisData.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取当前选中分类的表情列表
    final emojis = emojisData[selectedCategory.value] ?? [];

    // 表情列表为空
    if (emojis.isEmpty) {
      return Center(
        child: Text('暂无表情', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    // 优化：使用网格布局性能更好
    return RepaintBoundary(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1.0,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: emojis.length,
        // 使用cacheExtent提高滚动性能
        cacheExtent: 1000,
        // 禁用过度滚动效果，提高性能
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onEmojiSelected(emojis[index]),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              alignment: Alignment.center,
              child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }
}
