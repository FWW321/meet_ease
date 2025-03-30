import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_constants.dart';

class NotificationSettingsPage extends HookConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 通知开关
          _buildSection(
            context,
            title: '通知类型',
            children: [
              SwitchListTile(
                title: const Text('会议邀请'),
                subtitle: const Text('当您被邀请参加会议时接收通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('会议邀请通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('会议提醒'),
                subtitle: const Text('在会议开始前接收提醒通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('会议提醒通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('会议变更'),
                subtitle: const Text('当会议时间、地点等信息变更时接收通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('会议变更通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('会议取消'),
                subtitle: const Text('当会议被取消时接收通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('会议取消通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('议程更新'),
                subtitle: const Text('当会议议程更新时接收通知'),
                value: false, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('议程更新通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('投票开始'),
                subtitle: const Text('当会议中有新投票开始时接收通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('投票开始通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('系统公告'),
                subtitle: const Text('接收系统更新、维护等重要公告'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('系统公告通知${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 提醒时间设置
          _buildSection(
            context,
            title: '提醒时间',
            children: [
              ListTile(
                title: const Text('会议提醒时间'),
                subtitle: const Text('会议开始前15分钟'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showReminderTimeDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 通知方式
          _buildSection(
            context,
            title: '通知方式',
            children: [
              CheckboxListTile(
                title: const Text('应用内通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('应用内通知${value! ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              CheckboxListTile(
                title: const Text('系统通知'),
                value: true, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('系统通知${value! ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              CheckboxListTile(
                title: const Text('邮件通知'),
                value: false, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('邮件通知${value! ? '已开启' : '已关闭'}')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 免打扰时间
          _buildSection(
            context,
            title: '免打扰时间',
            children: [
              SwitchListTile(
                title: const Text('开启免打扰模式'),
                value: false, // 从用户设置中获取
                onChanged: (value) {
                  // TODO: 更新用户通知设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('免打扰模式${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),
              ListTile(
                title: const Text('免打扰时段'),
                subtitle: const Text('22:00 - 08:00'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                enabled: false, // 根据免打扰模式是否开启来设置
                onTap: () {
                  // TODO: 显示设置免打扰时段的对话框
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建设置分区
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }

  // 显示设置提醒时间的对话框
  void _showReminderTimeDialog(BuildContext context) {
    // 提醒时间选项（分钟）
    final reminderOptions = [5, 10, 15, 30, 60, 120, 1440]; // 1440分钟 = 1天
    final reminderTexts = [
      '5分钟前',
      '10分钟前',
      '15分钟前',
      '30分钟前',
      '1小时前',
      '2小时前',
      '1天前',
    ];

    // 当前选择的提醒时间
    int selectedReminderTime = 15; // 从用户设置中获取

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('会议提醒时间'),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder:
                    (context, setState) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        reminderOptions.length,
                        (index) => RadioListTile<int>(
                          title: Text(reminderTexts[index]),
                          value: reminderOptions[index],
                          groupValue: selectedReminderTime,
                          onChanged: (value) {
                            setState(() {
                              selectedReminderTime = value!;
                            });
                          },
                        ),
                      ),
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: 保存提醒时间设置
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('提醒时间设置已保存')));
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }
}
