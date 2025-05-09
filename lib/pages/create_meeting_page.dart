import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart' as models;
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../utils/meeting_utils.dart';
import '../widgets/user_selection_dialog.dart';

class CreateMeetingPage extends HookConsumerWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();

    // 表单字段控制器
    final titleController = useTextEditingController();
    final locationController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final passwordController = useTextEditingController();
    final meetingTypeController = useTextEditingController(); // 新增：会议类型输入控制器

    // 日期和时间
    final startDate = useState(DateTime.now().add(const Duration(hours: 1)));
    final endDate = useState(DateTime.now().add(const Duration(hours: 2)));

    // 会议可见性
    final meetingVisibility = useState(models.MeetingVisibility.public);

    // 是否启用密码
    final enablePassword = useState(false);

    // 选中的用户列表
    final selectedUserIds = useState<List<String>>([]);

    // 记录已选用户数量的快照，用于显示
    final selectedUsersCount = useState(0);

    // 创建会议状态
    final createMeetingState = ref.watch(createMeetingProvider);

    // 自定义滚动控制器
    final scrollController = useScrollController(keepScrollOffset: true);

    // 选择用户的弹窗方法
    Future<void> showUserSelectionFunc() async {
      final result = await showUserSelectionDialog(
        context: context,
        initialSelectedUserIds: selectedUserIds.value,
      );

      if (result != null) {
        selectedUserIds.value = result;
        selectedUsersCount.value = result.length;
      }
    }

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

    // 表单验证和提交
    Future<void> submitForm() async {
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
      final duration = endDate.value.difference(startDate.value);
      if (duration.inMinutes < 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会议时长至少需要15分钟'),
            backgroundColor: Colors.red,
          ),
        );
        isValid = false;
      }

      // 3. 如果是私有会议，必须选择至少一名其他用户
      if (meetingVisibility.value == models.MeetingVisibility.private) {
        // 获取当前用户ID
        final currentUserId = await ref.read(
          currentLoggedInUserIdProvider.future,
        );

        // 计算不包括当前用户的已选择用户数量
        final actualSelectedCount =
            selectedUserIds.value.where((id) => id != currentUserId).length;

        if (actualSelectedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('私有会议必须选择至少一名其他用户'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: '选择用户',
                onPressed: showUserSelectionFunc,
              ),
            ),
          );
          isValid = false;
        }
      }

      if (isValid) {
        // 获取当前用户ID
        final currentUserIdAsync = await ref.read(
          currentLoggedInUserIdProvider.future,
        );

        // 调用创建会议方法
        final notifier = ref.read(createMeetingProvider.notifier);

        // 如果列表中包含当前用户ID，需要移除
        final List<String> allowedUsersList =
            meetingVisibility.value == models.MeetingVisibility.private
                ? selectedUserIds.value
                    .where((id) => id != currentUserIdAsync)
                    .toList()
                    .cast<String>()
                : [];

        // 解析会议类型
        models.MeetingType parsedType = models.MeetingType.other;
        final typeText = meetingTypeController.text.trim();

        // 尝试匹配会议类型
        if (typeText.contains('常规') || typeText == '常规会议') {
          parsedType = models.MeetingType.regular;
        } else if (typeText.contains('培训') || typeText == '培训会议') {
          parsedType = models.MeetingType.training;
        } else if (typeText.contains('面试') || typeText == '面试会议') {
          parsedType = models.MeetingType.interview;
        }

        await notifier.create(
          title: titleController.text.trim(),
          location: locationController.text.trim(),
          startTime: startDate.value,
          endTime: endDate.value,
          description: descriptionController.text.trim(),
          type: parsedType,
          visibility: meetingVisibility.value,
          allowedUsers: allowedUsersList,
          password:
              enablePassword.value ? passwordController.text.trim() : null,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('创建会议')),
      body: Form(
        key: formKey,
        child: ListView(
          controller: scrollController,
          key: const PageStorageKey<String>('createMeetingPageScrollView'),
          padding: const EdgeInsets.all(16.0),
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

            // 会议类型输入
            TextFormField(
              controller: meetingTypeController,
              decoration: const InputDecoration(
                labelText: '会议类型',
                hintText: '如：常规会议、培训会议、面试会议等',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议类型';
                }
                if (value.trim().length < 2) {
                  return '会议类型至少需要2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议可见性选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '会议可见性',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.visibility),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<models.MeetingVisibility>(
                      value: meetingVisibility.value,
                      isExpanded: true,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          meetingVisibility.value = newValue;

                          // 重置已选用户列表，当可见性从私有变为其他类型时
                          if (newValue != models.MeetingVisibility.private) {
                            selectedUserIds.value = [];
                            selectedUsersCount.value = 0;
                          }

                          // 当切换到私有会议时，禁用密码功能
                          if (newValue == models.MeetingVisibility.private) {
                            enablePassword.value = false;
                            passwordController.clear();
                          }
                        }
                      },
                      items:
                          models.MeetingVisibility.values.map((visibility) {
                            return DropdownMenuItem<models.MeetingVisibility>(
                              value: visibility,
                              child: Text(getMeetingVisibilityText(visibility)),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 不同可见性的提示信息
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    getMeetingVisibilityDescription(meetingVisibility.value),
                    style: TextStyle(
                      color: _getVisibilityColor(meetingVisibility.value),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 用户选择区域 - 仅在私有会议时显示
            if (meetingVisibility.value == models.MeetingVisibility.private)
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
                          const Icon(Icons.people, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '参与用户',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.edit),
                            label: Text(
                              selectedUserIds.value.isEmpty ? '选择用户' : '修改选择',
                            ),
                            onPressed: showUserSelectionFunc,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 只在有选择用户时显示用户信息区域
                      if (selectedUserIds.value.isNotEmpty) ...[
                        Consumer(
                          builder: (context, ref, child) {
                            final currentUserIdAsync = ref.watch(
                              currentLoggedInUserIdProvider,
                            );

                            return currentUserIdAsync.when(
                              data: (currentUserId) {
                                // 过滤掉当前用户
                                final actualSelectedCount =
                                    selectedUserIds.value
                                        .where((id) => id != currentUserId)
                                        .length;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '已选择 $actualSelectedCount 名参与用户',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // 如果选择用户数量较多，增加可滚动区域
                                      actualSelectedCount > 5
                                          ? SizedBox(
                                            height: 40,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i < actualSelectedCount;
                                                    i++
                                                  )
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 6,
                                                          ),
                                                      child: Chip(
                                                        label: Text(
                                                          'User ${i + 1}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          )
                                          : Text(
                                            '点击"修改选择"按钮可编辑参与用户',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                    ],
                                  ),
                                );
                              },
                              loading:
                                  () => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              error:
                                  (_, __) => Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Text(
                                      '加载用户信息失败',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 会议密码设置 - 仅在非私有会议时显示
            if (meetingVisibility.value != models.MeetingVisibility.private)
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
                          Switch(
                            value: enablePassword.value,
                            onChanged: (value) {
                              enablePassword.value = value;
                              if (!value) {
                                passwordController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                      // 只有启用密码时才显示密码输入框
                      if (enablePassword.value)
                        Column(
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
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
                              },
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
                      else
                        const Text(
                          '不启用密码，所有参会者可直接加入会议。',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 开始时间选择
            InkWell(
              onTap: () => _selectDateTime(context, startDate, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '开始时间',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(startDate.value),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 结束时间选择
            InkWell(
              onTap: () => _selectDateTime(context, endDate, false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '结束时间',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(endDate.value),
                ),
              ),
            ),

            // 时间验证错误提示
            if (endDate.value.isBefore(startDate.value) ||
                endDate.value.isAtSameMomentAs(startDate.value))
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '结束时间必须晚于开始时间',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // 检查会议时长是否合理
            if (endDate.value.difference(startDate.value).inMinutes < 15)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '会议时长至少需要15分钟',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            if (endDate.value.difference(startDate.value).inHours > 24)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '会议时长不建议超过24小时',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
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
            ElevatedButton(
              onPressed: createMeetingState.isLoading ? null : submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
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
            ),
            const SizedBox(height: 32),
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
    if (!context.mounted) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;
    if (!context.mounted) return;

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

  // 获取会议可见性的颜色
  Color _getVisibilityColor(models.MeetingVisibility visibility) {
    switch (visibility) {
      case models.MeetingVisibility.public:
        return Colors.blue;
      case models.MeetingVisibility.private:
        return Colors.red;
    }
  }
}
