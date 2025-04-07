import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';

class CreateMeetingPage extends HookConsumerWidget {
  const CreateMeetingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();

    // 表单字段控制器
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();

    // 日期和时间
    final startDate = ValueNotifier<DateTime>(
      DateTime.now().add(const Duration(hours: 1)),
    );
    final endDate = ValueNotifier<DateTime>(
      DateTime.now().add(const Duration(hours: 2)),
    );

    // 会议类型和可见性
    final meetingType = ValueNotifier<MeetingType>(MeetingType.regular);
    final meetingVisibility = ValueNotifier<MeetingVisibility>(
      MeetingVisibility.public,
    );

    // 可选择的用户列表（对于私有会议）
    final selectedUsers = ValueNotifier<List<String>>([]);

    // 创建会议状态
    final createMeetingState = ref.watch(createMeetingProvider);

    // 监听创建状态的改变
    ref.listen(createMeetingProvider, (previous, next) {
      next.whenData((meeting) {
        if (meeting != null && previous?.value != meeting) {
          // 成功创建会议，返回上一页
          Navigator.of(context).pop(true);

          // 显示成功信息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('会议创建成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });

      // 显示错误信息
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('创建失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('创建会议')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 会议标题
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '会议标题',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议地点
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: '会议地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议地点';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议类型选择
            ValueListenableBuilder<MeetingType>(
              valueListenable: meetingType,
              builder: (context, type, _) {
                return InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '会议类型',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MeetingType>(
                      value: type,
                      isExpanded: true,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          meetingType.value = newValue;
                        }
                      },
                      items:
                          MeetingType.values.map((type) {
                            return DropdownMenuItem<MeetingType>(
                              value: type,
                              child: Text(getMeetingTypeText(type)),
                            );
                          }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 会议可见性选择
            ValueListenableBuilder<MeetingVisibility>(
              valueListenable: meetingVisibility,
              builder: (context, visibility, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '会议可见性',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.visibility),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MeetingVisibility>(
                          value: visibility,
                          isExpanded: true,
                          onChanged: (newValue) {
                            if (newValue != null) {
                              meetingVisibility.value = newValue;
                            }
                          },
                          items:
                              MeetingVisibility.values.map((visibility) {
                                return DropdownMenuItem<MeetingVisibility>(
                                  value: visibility,
                                  child: Text(
                                    getMeetingVisibilityText(visibility),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 不同可见性的提示信息
                    _buildVisibilityHelperText(visibility),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 当选择私有会议时，显示用户选择列表
            ValueListenableBuilder<MeetingVisibility>(
              valueListenable: meetingVisibility,
              builder: (context, visibility, _) {
                if (visibility == MeetingVisibility.private) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择可参与的用户',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 这里应该实现用户选择逻辑，为简化示例，使用模拟数据
                      _buildUserSelectionList(selectedUsers),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 开始时间选择
            ValueListenableBuilder<DateTime>(
              valueListenable: startDate,
              builder: (context, date, _) {
                return InkWell(
                  onTap: () => _selectDateTime(context, startDate, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '开始时间',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 结束时间选择
            ValueListenableBuilder<DateTime>(
              valueListenable: endDate,
              builder: (context, date, _) {
                return InkWell(
                  onTap: () => _selectDateTime(context, endDate, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '结束时间',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 会议描述
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '会议描述',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 创建按钮
            ValueListenableBuilder<MeetingVisibility>(
              valueListenable: meetingVisibility,
              builder: (context, visibility, _) {
                return ValueListenableBuilder<List<String>>(
                  valueListenable: selectedUsers,
                  builder: (context, users, _) {
                    // 检查私有会议是否选择了用户
                    final bool canSubmit =
                        visibility != MeetingVisibility.private ||
                        users.isNotEmpty;

                    return ElevatedButton(
                      onPressed:
                          createMeetingState.isLoading
                              ? null
                              : () => _submitForm(
                                context,
                                ref,
                                formKey,
                                titleController.text,
                                locationController.text,
                                descriptionController.text,
                                startDate.value,
                                endDate.value,
                                meetingType.value,
                                meetingVisibility.value,
                                selectedUsers.value,
                              ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child:
                          createMeetingState.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('创建会议'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 提交表单
  Future<void> _submitForm(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    String title,
    String location,
    String description,
    DateTime startTime,
    DateTime endTime,
    MeetingType type,
    MeetingVisibility visibility,
    List<String> allowedUsers,
  ) async {
    // 验证表单
    if (!formKey.currentState!.validate()) {
      return;
    }

    // 检查开始时间和结束时间
    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('结束时间不能早于开始时间'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 对于私有会议，检查是否选择了用户
    if (visibility == MeetingVisibility.private && allowedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('私有会议需要选择至少一名参与者'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 创建会议
    try {
      await ref
          .read(createMeetingProvider.notifier)
          .create(
            title: title,
            startTime: startTime,
            endTime: endTime,
            location: location,
            type: type,
            visibility: visibility,
            description: description,
            allowedUsers: allowedUsers,
          );
    } catch (e) {
      // 错误处理在 ref.listen 中
    }
  }

  // 选择日期和时间
  Future<void> _selectDateTime(
    BuildContext context,
    ValueNotifier<DateTime> dateTimeNotifier,
    bool isStartTime,
  ) async {
    final DateTime initialDate = dateTimeNotifier.value;

    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStartTime ? DateTime.now() : dateTimeNotifier.value,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    // 组合日期和时间
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    dateTimeNotifier.value = newDateTime;
  }

  // 创建会议可见性提示
  Widget _buildVisibilityHelperText(MeetingVisibility visibility) {
    String helperText;
    Color color;

    switch (visibility) {
      case MeetingVisibility.public:
        helperText = '公开会议对所有人可见，所有人可参加';
        color = Colors.blue;
        break;
      case MeetingVisibility.searchable:
        helperText = '可搜索会议需要通过搜索才能显示，所有人可参加';
        color = Colors.orange;
        break;
      case MeetingVisibility.private:
        helperText = '私有会议只对特定人员可见，需要选择参与人员';
        color = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        helperText,
        style: TextStyle(color: color, fontStyle: FontStyle.italic),
      ),
    );
  }

  // 用户选择列表（简化示例）
  Widget _buildUserSelectionList(ValueNotifier<List<String>> selectedUsers) {
    // 模拟数据
    final List<User> mockUsers = [
      User(id: 'user2', name: '李四'),
      User(id: 'user3', name: '王五'),
      User(id: 'user4', name: '赵六'),
      User(id: 'user5', name: '孙七'),
      User(id: 'user6', name: '周八'),
    ];

    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedUsers,
      builder: (context, selectedIds, _) {
        return Column(
          children:
              mockUsers.map((user) {
                final bool isSelected = selectedIds.contains(user.id);

                return CheckboxListTile(
                  title: Text(user.name),
                  subtitle: Text(user.id),
                  value: isSelected,
                  onChanged: (bool? value) {
                    final newList = List<String>.from(selectedIds);
                    if (value == true) {
                      if (!newList.contains(user.id)) {
                        newList.add(user.id);
                      }
                    } else {
                      newList.remove(user.id);
                    }
                    selectedUsers.value = newList;
                  },
                );
              }).toList(),
        );
      },
    );
  }
}

// 简化的用户模型，仅用于示例
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}
