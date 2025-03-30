import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import 'meeting_page.dart';
import 'my_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  // 内容页面列表
  final List<Widget> _contentPages = [
    const MeetingPage(),
    MyPage(),
  ];

  // 跳转到我的页面
  void _jumpToMyPage() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onAvatarTap: _jumpToMyPage),
      body: _contentPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: '会议'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}