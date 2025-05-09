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
    // 会议类型文本控制器
    final typeController = useTextEditingController(
      text: getMeetingTypeText(meeting.type),
    );

    // 日期选择
    final startTime = useState(meeting.startTime);
    final endTime = useState(meeting.endTime);

    // 获取主题色
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    // 计算时间差
    final duration = endTime.value.difference(startTime.value);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText = '${hours}小时${minutes > 0 ? ' ${minutes}分钟' : ''}';

    return Container(
      color: backgroundColor.withOpacity(0.5),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // 会议基本信息卡片
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        '编辑会议详情',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 会议状态指示
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            meeting.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(
                              meeting.status,
                            ).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(meeting.status),
                              size: 16,
                              color: _getStatusColor(meeting.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              getMeetingStatusText(meeting.status),
                              style: TextStyle(
                                color: _getStatusColor(meeting.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // 会议标题
                      TextField(
                        controller: titleController,
                        decoration: _getInputDecoration(
                          label: '会议标题',
                          hint: '输入会议标题',
                          icon: Icons.title,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 会议描述
                      TextField(
                        controller: descriptionController,
                        decoration: _getInputDecoration(
                          label: '会议描述',
                          hint: '输入会议描述（可选）',
                          icon: Icons.description,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16.0),

                      // 会议地点
                      TextField(
                        controller: locationController,
                        decoration: _getInputDecoration(
                          label: '会议地点',
                          hint: '输入会议地点',
                          icon: Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 会议时间板块
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.blue.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '会议时间',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '时长: $durationText',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 开始时间选择
                            GestureDetector(
                              onTap:
                                  () => _selectDateTime(
                                    context,
                                    startTime,
                                    isStart: true,
                                  ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.blue.shade700,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '开始时间',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.edit,
                                          color: Colors.grey.shade600,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${startTime.value.year}-${startTime.value.month.toString().padLeft(2, '0')}-${startTime.value.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${startTime.value.hour.toString().padLeft(2, '0')}:${startTime.value.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 结束时间选择
                            GestureDetector(
                              onTap:
                                  () => _selectDateTime(
                                    context,
                                    endTime,
                                    isStart: false,
                                  ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.stop_circle_outlined,
                                          color: Colors.red.shade400,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '结束时间',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.edit,
                                          color: Colors.grey.shade600,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${endTime.value.year}-${endTime.value.month.toString().padLeft(2, '0')}-${endTime.value.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${endTime.value.hour.toString().padLeft(2, '0')}:${endTime.value.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 会议类型 - 改为手动输入
                      TextField(
                        controller: typeController,
                        decoration: _getInputDecoration(
                          label: '会议类型',
                          hint: '例如：普通会议、培训会议、面试会议',
                          icon: Icons.category,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 保存按钮
          Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed:
                  () => _updateMeetingInfo(
                    context,
                    ref,
                    titleController.text,
                    descriptionController.text,
                    locationController.text,
                    startTime.value,
                    endTime.value,
                    _getTypeFromText(typeController.text),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded),
                  SizedBox(width: 10),
                  Text(
                    '保存会议信息',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 获取输入框装饰
  InputDecoration _getInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // 获取状态颜色
  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.upcoming:
        return Colors.blue;
      case MeetingStatus.ongoing:
        return Colors.green;
      case MeetingStatus.completed:
        return Colors.grey;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }

  // 获取状态图标
  IconData _getStatusIcon(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.upcoming:
        return Icons.schedule;
      case MeetingStatus.ongoing:
        return Icons.meeting_room;
      case MeetingStatus.completed:
        return Icons.event_available;
      case MeetingStatus.cancelled:
        return Icons.event_busy;
    }
  }

  // 从文本获取会议类型枚举
  MeetingType _getTypeFromText(String typeText) {
    switch (typeText.trim()) {
      case '培训会议':
        return MeetingType.training;
      case '面试会议':
        return MeetingType.interview;
      case '其他':
        return MeetingType.other;
      default:
        return MeetingType.regular;
    }
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
  void _updateMeetingInfo(
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
