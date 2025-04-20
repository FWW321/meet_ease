import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 表情服务，用于动态加载表情数据
class EmojiService {
  /// 从资源文件加载所有表情数据
  Future<Map<String, List<String>>> loadEmojis() async {
    try {
      final jsonString = await rootBundle.loadString('assets/emoji_data.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final Map<String, List<String>> emojis = {};

      jsonData.forEach((key, value) {
        if (value is List) {
          emojis[key] = List<String>.from(value);
        }
      });

      return emojis;
    } catch (e) {
      // 加载失败时返回空Map，不影响应用运行
      return {};
    }
  }
}

/// 提供EmojiService的Provider
final emojiServiceProvider = Provider<EmojiService>((ref) {
  return EmojiService();
});

/// 提供所有表情数据的异步Provider
final emojisProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final emojiService = ref.read(emojiServiceProvider);
  return await emojiService.loadEmojis();
});
