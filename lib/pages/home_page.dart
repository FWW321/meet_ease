import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../widgets/app_bar.dart';
import '../providers/user_providers.dart';
import 'meeting_page.dart';
import 'my_page.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前选中的页面索引
    final currentIndex = useState<int>(0);

    // 内容页面列表
    final contentPages = const [MeetingPage(), MyPage()];

    // 跳转到我的页面
    void jumpToMyPage() {
      currentIndex.value = 1;
    }

    // 获取用户信息
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: CustomAppBar(
        onAvatarTap: jumpToMyPage,
        // 从用户状态中获取头像URL
        avatarUrl: userAsync.valueOrNull?.avatarUrl,
      ),
      body: contentPages[currentIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: '会议'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
