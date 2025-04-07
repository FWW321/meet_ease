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
    final passwordController = TextEditingController();

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

    // 是否启用密码
    final enablePassword = ValueNotifier<bool>(false);

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
              maxLength: 50, // 限制标题最大长度为50个字符
              decoration: const InputDecoration(
                labelText: '会议标题',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                counterText: '', // 隐藏内置的字符计数
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议标题';
                }
                if (value.trim().length < 3) {
                  return '会议标题至少需要3个字符';
                }
                if (value.trim().length > 50) {
                  return '会议标题不能超过50个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议地点
            TextFormField(
              controller: locationController,
              maxLength: 100, // 限制地点最大长度
              decoration: const InputDecoration(
                labelText: '会议地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议地点';
                }
                if (value.trim().length < 2) {
                  return '会议地点至少需要2个字符';
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

                              // 重置已选用户列表，当可见性从私有变为其他类型时
                              if (newValue != MeetingVisibility.private) {
                                selectedUsers.value = [];
                              }
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

            // 会议密码设置
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '会议密码',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: enablePassword,
                          builder: (context, enabled, _) {
                            return Switch(
                              value: enabled,
                              onChanged: (value) {
                                enablePassword.value = value;
                                if (!value) {
                                  passwordController.clear();
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: enablePassword,
                      builder: (context, enabled, _) {
                        return enabled
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true, // 隐藏密码
                                  decoration: const InputDecoration(
                                    labelText: '设置密码',
                                    hintText: '参会者需要输入此密码才能加入会议',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      enabled
                                          ? (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return '请输入会议密码';
                                            }
                                            if (value.length < 4) {
                                              return '密码长度至少为4位';
                                            }
                                            if (value.length > 16) {
                                              return '密码长度不能超过16位';
                                            }
                                            // 验证密码格式，可以根据需要增加字母、数字等要求
                                            if (!RegExp(
                                              r'^[a-zA-Z0-9]+$',
                                            ).hasMatch(value)) {
                                              return '密码只能包含字母和数字';
                                            }
                                            return null;
                                          }
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '启用密码后，参会者需要输入正确的密码才能加入会议。',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                            : const Text(
                              '不启用密码，所有参会者可直接加入会议。',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
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
                      // 显示选择用户提示
                      ValueListenableBuilder<List<String>>(
                        valueListenable: selectedUsers,
                        builder: (context, selectedIds, _) {
                          if (selectedIds.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8.0, left: 16.0),
                              child: Text(
                                '请至少选择一名用户',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              left: 16.0,
                            ),
                            child: Text(
                              '已选择 ${selectedIds.length} 名用户',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
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
            // 时间验证错误提示
            ValueListenableBuilder<DateTime>(
              valueListenable: startDate,
              builder: (context, startTime, _) {
                return ValueListenableBuilder<DateTime>(
                  valueListenable: endDate,
                  builder: (context, endTime, _) {
                    if (endTime.isBefore(startTime) ||
                        endTime.isAtSameMomentAs(startTime)) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Text(
                          '结束时间必须晚于开始时间',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }
                    // 检查会议时长是否合理
                    final duration = endTime.difference(startTime);
                    if (duration.inMinutes < 15) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Text(
                          '会议时长至少需要15分钟',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }
                    if (duration.inHours > 24) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0, left: 16.0),
                        child: Text(
                          '会议时长不建议超过24小时',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // 会议描述
            TextFormField(
              controller: descriptionController,
              maxLength: 500, // 限制描述最大长度
              decoration: const InputDecoration(
                labelText: '会议描述',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return '会议描述不能超过500个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 创建按钮
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ElevatedButton(
                onPressed:
                    createMeetingState.isLoading
                        ? null
                        : () async {
                          bool isValid = formKey.currentState!.validate();

                          // 额外验证
                          // 1. 检查结束时间是否晚于开始时间
                          if (endDate.value.isBefore(startDate.value) ||
                              endDate.value.isAtSameMomentAs(startDate.value)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('结束时间必须晚于开始时间'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          // 2. 检查会议时长是否至少15分钟
                          final duration = endDate.value.difference(
                            startDate.value,
                          );
                          if (duration.inMinutes < 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('会议时长至少需要15分钟'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          // 3. 如果是私有会议，必须选择至少一名用户
                          if (meetingVisibility.value ==
                                  MeetingVisibility.private &&
                              selectedUsers.value.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('私有会议必须选择至少一名用户'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          if (isValid) {
                            // 调用创建会议方法
                            final notifier = ref.read(
                              createMeetingProvider.notifier,
                            );

                            await notifier.create(
                              title: titleController.text.trim(),
                              location: locationController.text.trim(),
                              startTime: startDate.value,
                              endTime: endDate.value,
                              description: descriptionController.text.trim(),
                              type: meetingType.value,
                              visibility: meetingVisibility.value,
                              allowedUsers:
                                  meetingVisibility.value ==
                                          MeetingVisibility.private
                                      ? selectedUsers.value
                                      : [],
                              password:
                                  enablePassword.value
                                      ? passwordController.text.trim()
                                      : null,
                            );
                          }
                        },
                child:
                    createMeetingState.isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('创建会议'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      firstDate:
          isStartTime
              ? DateTime.now() // 开始时间不早于当前时间
              : DateTime.now(), // 结束时间不早于当前时间（实际使用时应该不早于开始时间，但这里简化处理）
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
        helperText = '可搜索会议仅通过会议码搜索才能显示，将自动生成6位数字会议码';
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

// 获取会议类型文本
String getMeetingTypeText(MeetingType type) {
  switch (type) {
    case MeetingType.regular:
      return '常规会议';
    case MeetingType.training:
      return '培训会议';
    case MeetingType.interview:
      return '面试会议';
    case MeetingType.other:
      return '其他类型';
  }
}

// 获取会议可见性文本
String getMeetingVisibilityText(MeetingVisibility visibility) {
  switch (visibility) {
    case MeetingVisibility.public:
      return '公开会议';
    case MeetingVisibility.searchable:
      return '可搜索会议';
    case MeetingVisibility.private:
      return '私有会议';
  }
}
