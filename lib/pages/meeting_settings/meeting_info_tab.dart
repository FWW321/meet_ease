import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';

/// 会议信息标签页
class MeetingInfoTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const MeetingInfoTab({
    required this.meeting,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 标题控制器
    final titleController = useTextEditingController(text: meeting.title);
    final descriptionController = useTextEditingController(
      text: meeting.description ?? '',
    );
    final locationController = useTextEditingController(text: meeting.location);

    // 日期选择
    final startTime = useState(meeting.startTime);
    final endTime = useState(meeting.endTime);

    // 会议类型
    final meetingType = useState(meeting.type);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 会议基本信息卡片
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '基本信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),

                // 会议标题
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '会议标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),

                // 会议描述
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '会议描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),

                // 会议地点
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: '会议地点',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),

                // 会议时间
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            () => _selectDateTime(
                              context,
                              startTime,
                              isStart: true,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '开始时间',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${startTime.value.year}-${startTime.value.month.toString().padLeft(2, '0')}-${startTime.value.day.toString().padLeft(2, '0')} ${startTime.value.hour.toString().padLeft(2, '0')}:${startTime.value.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            () => _selectDateTime(
                              context,
                              endTime,
                              isStart: false,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '结束时间',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${endTime.value.year}-${endTime.value.month.toString().padLeft(2, '0')}-${endTime.value.day.toString().padLeft(2, '0')} ${endTime.value.hour.toString().padLeft(2, '0')}:${endTime.value.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // 会议类型
                DropdownButtonFormField<MeetingType>(
                  decoration: const InputDecoration(
                    labelText: '会议类型',
                    border: OutlineInputBorder(),
                  ),
                  value: meetingType.value,
                  items:
                      MeetingType.values.map((type) {
                        return DropdownMenuItem<MeetingType>(
                          value: type,
                          child: Text(getMeetingTypeText(type)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      meetingType.value = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // 会议参与设置卡片
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '参与设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),

                // 权限设置
                SwitchListTile(
                  title: const Text('允许参与者发言'),
                  subtitle: const Text('开启后，所有参与者可以直接发言'),
                  value: true, // 从会议设置中获取实际值
                  onChanged: (value) {
                    // TODO: 实现权限变更功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('发言权限${value ? '已开启' : '已关闭'}')),
                    );
                  },
                ),

                SwitchListTile(
                  title: const Text('允许参与者共享屏幕'),
                  subtitle: const Text('开启后，所有参与者可以共享自己的屏幕'),
                  value: false, // 从会议设置中获取实际值
                  onChanged: (value) {
                    // TODO: 实现权限变更功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('屏幕共享权限${value ? '已开启' : '已关闭'}')),
                    );
                  },
                ),

                SwitchListTile(
                  title: const Text('允许参与者上传文件'),
                  subtitle: const Text('开启后，所有参与者可以上传文件到会议'),
                  value: true, // 从会议设置中获取实际值
                  onChanged: (value) {
                    // TODO: 实现权限变更功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('文件上传权限${value ? '已开启' : '已关闭'}')),
                    );
                  },
                ),

                SwitchListTile(
                  title: const Text('允许参与者创建投票'),
                  subtitle: const Text('开启后，所有参与者可以创建会议投票'),
                  value: false, // 从会议设置中获取实际值
                  onChanged: (value) {
                    // TODO: 实现权限变更功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('投票创建权限${value ? '已开启' : '已关闭'}')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 会议通知设置卡片
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '通知设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),

                SwitchListTile(
                  title: const Text('会议开始提醒'),
                  subtitle: const Text('在会议开始前向所有参与者发送提醒'),
                  value: true, // 从会议设置中获取实际值
                  onChanged: (value) {
                    // TODO: 实现提醒设置功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('会议提醒${value ? '已开启' : '已关闭'}')),
                    );
                  },
                ),

                ListTile(
                  title: const Text('提醒时间'),
                  subtitle: const Text('会议开始前 15 分钟'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: 实现提醒时间设置弹窗
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('提醒时间设置功能开发中')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 保存按钮
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ElevatedButton(
            onPressed:
                () => _saveMeetingInfo(
                  context,
                  ref,
                  titleController.text,
                  descriptionController.text,
                  locationController.text,
                  startTime.value,
                  endTime.value,
                  meetingType.value,
                ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16.0),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('保存会议设置'),
          ),
        ),
      ],
    );
  }

  // 选择日期和时间
  Future<void> _selectDateTime(
    BuildContext context,
    ValueNotifier<DateTime> dateTime, {
    required bool isStart,
  }) async {
    // 如果是修改开始时间，并且会议不是即将开始状态，显示提示
    if (isStart && meeting.status != MeetingStatus.upcoming) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('只有即将开始的会议才能修改开始时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateTime.value,
      firstDate: isStart ? DateTime.now() : (meeting.startTime),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(dateTime.value),
      );

      if (pickedTime != null) {
        dateTime.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  // 保存会议信息
  void _saveMeetingInfo(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    String location,
    DateTime startTime,
    DateTime endTime,
    MeetingType type,
  ) {
    // 验证输入
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会议标题不能为空'), backgroundColor: Colors.red),
      );
      return;
    }

    if (startTime.isAfter(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('开始时间不能晚于结束时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查是否修改了开始时间
    final isStartTimeChanged = startTime != meeting.startTime;

    // 如果修改了开始时间，但会议不是即将开始状态，显示错误
    if (isStartTimeChanged && meeting.status != MeetingStatus.upcoming) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('只有即将开始的会议才能修改开始时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 更新会议信息
    final meetingService = ref.read(meetingServiceProvider);

    meetingService
        .updateMeeting(
          meeting.id,
          title: title,
          description: description,
          location: location,
          startTime: isStartTimeChanged ? startTime : null, // 只有修改了才传递
          endTime: endTime,
          type: type,
        )
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('会议信息更新成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('更新会议信息失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}
