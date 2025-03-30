import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/meeting.dart';
import '../widgets/agenda_list_widget.dart';
import '../widgets/materials_list_widget.dart';
import '../widgets/notes_list_widget.dart';
import '../widgets/votes_list_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/speech_requests_widget.dart';

/// 会议过程管理页面 - 以聊天室为主要内容的界面
class MeetingProcessPage extends ConsumerStatefulWidget {
  final String meetingId;
  final Meeting meeting;

  const MeetingProcessPage({
    required this.meetingId,
    required this.meeting,
    super.key,
  });

  @override
  ConsumerState<MeetingProcessPage> createState() => _MeetingProcessPageState();
}

class _MeetingProcessPageState extends ConsumerState<MeetingProcessPage> {
  // 当前选中的功能选项
  int _selectedFeatureIndex = 0;

  // 功能选项列表
  final List<_MeetingFeature> _features = [
    _MeetingFeature(icon: Icons.list_alt, label: '议程', color: Colors.blue),
    _MeetingFeature(icon: Icons.folder, label: '资料', color: Colors.orange),
    _MeetingFeature(icon: Icons.note, label: '笔记', color: Colors.green),
    _MeetingFeature(icon: Icons.how_to_vote, label: '投票', color: Colors.purple),
    _MeetingFeature(
      icon: Icons.record_voice_over,
      label: '发言申请',
      color: Colors.pink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 判断是否为大屏设备
    final isLargeScreen = screenWidth > 1000;

    // 侧边导航宽度
    final navWidth = isLargeScreen ? 240.0 : 70.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meeting.title),
        actions: [
          // 会议信息按钮
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '会议信息',
            onPressed: () => _showMeetingInfo(context),
          ),

          // 更多选项按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'settings', child: Text('会议设置')),
                  const PopupMenuItem(value: 'invite', child: Text('邀请参会者')),
                  const PopupMenuItem(value: 'exit', child: Text('退出会议')),
                ],
            onSelected: (value) {
              // 处理菜单项选择
              switch (value) {
                case 'settings':
                  // 实现会议设置功能
                  break;
                case 'invite':
                  // 实现邀请参会者功能
                  break;
                case 'exit':
                  Navigator.of(context).pop();
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧功能导航栏
          Container(
            width: navWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // 功能选项列表
                Expanded(
                  child: ListView.builder(
                    itemCount: _features.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      final isSelected = index == _selectedFeatureIndex;

                      // 为大屏和小屏设计不同的导航项
                      return isLargeScreen
                          ? _buildLargeNavItem(feature, index, isSelected)
                          : _buildSmallNavItem(feature, index, isSelected);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 中间内容区域 - 动态内容面板
          Expanded(flex: 2, child: _buildFeaturePanel(_selectedFeatureIndex)),

          // 右侧聊天区域（固定显示）
          if (isLargeScreen)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 聊天区域标题
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline),
                          SizedBox(width: 8),
                          Text(
                            '在线交流',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 聊天内容
                    Expanded(
                      child: ChatWidget(
                        meetingId: widget.meetingId,
                        userId: 'currentUserId', // 替换为实际用户ID
                        userName: '当前用户', // 替换为实际用户名
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // 小屏幕下的浮动聊天按钮
      floatingActionButton:
          !isLargeScreen
              ? FloatingActionButton(
                onPressed: () => _showChatModal(context),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.chat),
              )
              : null,
    );
  }

  // 构建大屏导航项
  Widget _buildLargeNavItem(
    _MeetingFeature feature,
    int index,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        feature.icon,
        color: isSelected ? feature.color : Colors.grey,
      ),
      title: Text(
        feature.label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? feature.color : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: feature.color.withOpacity(0.1),
      onTap: () => setState(() => _selectedFeatureIndex = index),
    );
  }

  // 构建小屏导航项
  Widget _buildSmallNavItem(
    _MeetingFeature feature,
    int index,
    bool isSelected,
  ) {
    return Tooltip(
      message: feature.label,
      child: InkWell(
        onTap: () => setState(() => _selectedFeatureIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: isSelected ? feature.color : Colors.transparent,
              ),
            ),
            color: isSelected ? feature.color.withOpacity(0.1) : null,
          ),
          child: Icon(
            feature.icon,
            color: isSelected ? feature.color : Colors.grey,
            size: 28,
          ),
        ),
      ),
    );
  }

  // 根据选择的索引构建相应的功能面板
  Widget _buildFeaturePanel(int index) {
    switch (index) {
      case 0:
        return AgendaListWidget(meetingId: widget.meetingId);
      case 1:
        return MaterialsListWidget(meetingId: widget.meetingId);
      case 2:
        return NotesListWidget(meetingId: widget.meetingId);
      case 3:
        return VotesListWidget(meetingId: widget.meetingId);
      case 4:
        return SpeechRequestsWidget(
          meetingId: widget.meetingId,
          isOrganizer: widget.meeting.organizerId == 'currentUserId',
        );
      default:
        return const Center(child: Text('功能未实现'));
    }
  }

  // 显示会议信息对话框
  void _showMeetingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('会议信息'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('标题: ${widget.meeting.title}'),
                const SizedBox(height: 8),
                Text('开始时间: ${widget.meeting.startTime}'),
                const SizedBox(height: 8),
                Text('结束时间: ${widget.meeting.endTime}'),
                const SizedBox(height: 8),
                Text('组织者: ${widget.meeting.organizerId}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  // 在小屏幕上显示聊天模态窗口
  void _showChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    // 聊天模态窗口标题栏
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline),
                          const SizedBox(width: 8),
                          const Text(
                            '在线交流',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // 聊天内容
                    Expanded(
                      child: ChatWidget(
                        meetingId: widget.meetingId,
                        userId: 'currentUserId', // 替换为实际用户ID
                        userName: '当前用户', // 替换为实际用户名
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}

/// 会议功能项数据类
class _MeetingFeature {
  final IconData icon;
  final String label;
  final Color color;

  const _MeetingFeature({
    required this.icon,
    required this.label,
    required this.color,
  });
}
