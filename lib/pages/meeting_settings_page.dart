import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../widgets/user_selection_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';

/// 会议设置页面 - 仅会议创建者和管理员可访问
class MeetingSettingsPage extends HookConsumerWidget {
  final String meetingId;
  final String currentUserId;

  const MeetingSettingsPage({
    required this.meetingId,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取会议详情
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));

    // 当前选中的标签索引
    final selectedTabIndex = useState(0);

    // 标签列表
    final tabs = ['会议信息', '管理员', '黑名单'];

    return Scaffold(
      appBar: AppBar(title: const Text('会议设置'), centerTitle: true),
      body: meetingAsync.when(
        data: (meeting) {
          // 检查权限
          if (!meeting.canUserManage(currentUserId)) {
            return const Center(child: Text('您没有权限访问此页面'));
          }

          // 检查会议状态 - 只允许在即将开始或进行中的会议中修改设置
          if (meeting.status == MeetingStatus.completed) {
            return Center(
              child: Text('无法修改${getMeetingStatusText(meeting.status)}的会议设置'),
            );
          }

          // 对已取消的会议显示特别的提示
          if (meeting.status == MeetingStatus.cancelled) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '会议已被取消',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '无法修改已取消的会议设置',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('返回'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 标签选择器
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () => selectedTabIndex.value = index,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    selectedTabIndex.value == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Text(
                            tabs[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  selectedTabIndex.value == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                              fontWeight:
                                  selectedTabIndex.value == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: IndexedStack(
                  index: selectedTabIndex.value,
                  children: [
                    _MeetingInfoTab(
                      meeting: meeting,
                      currentUserId: currentUserId,
                    ),
                    _AdminsTab(meeting: meeting, currentUserId: currentUserId),
                    _BlacklistTab(
                      meeting: meeting,
                      currentUserId: currentUserId,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

/// 会议信息标签页
class _MeetingInfoTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const _MeetingInfoTab({required this.meeting, required this.currentUserId});

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

/// 管理员管理标签页
class _AdminsTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const _AdminsTab({required this.meeting, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有参与者（排除创建者和已有管理员）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
    );

    // 获取管理员列表
    final managersAsync = ref.watch(meetingManagersProvider(meeting.id));

    // 检查当前用户是否为会议创建者
    final isCreator = meeting.isCreatorOnly(currentUserId);

    // 打印调试信息
    managersAsync.whenOrNull(
      data:
          (managers) => print(
            '找到${managers.length}个管理员: ${managers.map((m) => '${m.id}-${m.name}').join(', ')}',
          ),
      error: (error, _) => print('获取管理员列表出错: $error'),
      loading: () => print('正在加载管理员列表...'),
    );

    return Column(
      children: [
        // 管理员列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 创建者信息（固定在顶部）
              _UserTile(
                userId: meeting.organizerId,
                label: '创建者',
                canRemove: false,
                onRemove: null,
              ),

              // 刷新按钮
              ListTile(
                title: const Text('手动刷新管理员列表'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // 刷新管理员列表
                    ref.invalidate(meetingManagersProvider(meeting.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在刷新管理员列表...')),
                    );
                  },
                ),
              ),

              const Divider(),

              // 现有管理员列表
              managersAsync.when(
                data: (managers) {
                  if (managers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          '尚未添加管理员',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        managers
                            .map(
                              (admin) => _UserTile(
                                userId: admin.id,
                                label: '管理员',
                                canRemove: isCreator,
                                onRemove: () {
                                  // 移除管理员
                                  _removeAdmin(context, ref, admin.id);
                                },
                              ),
                            )
                            .toList(),
                  );
                },
                loading:
                    () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, stackTrace) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              '加载管理员列表失败: $error',
                              style: TextStyle(color: Colors.red),
                            ),
                            if (stackTrace != null)
                              Text(
                                '堆栈: $stackTrace',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),

        // 底部添加按钮，只有创建者可以添加管理员
        if (isCreator)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAddAdminDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12.0),
                ),
                child: const Text('添加管理员'),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以添加管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 获取管理员ID列表和创建者ID，用于过滤
    final managersAsync = ref.read(meetingManagersProvider(meeting.id));
    final adminIds =
        managersAsync.whenOrNull(
          data: (managers) => managers.map((admin) => admin.id).toList(),
        ) ??
        [];
    final creatorId = meeting.organizerId;

    // 使用UserSelectionDialog来选择管理员，从所有用户中选择
    final selectedUserIds = await showUserSelectionDialog(
      context: context,
      initialSelectedUserIds: [], // 初始没有选择的管理员
    );

    // 如果用户取消了选择，则返回null
    if (selectedUserIds == null || selectedUserIds.isEmpty) return;

    // 过滤掉创建者ID和已有管理员ID
    final validSelectedIds =
        selectedUserIds
            .where((id) => id != creatorId && !adminIds.contains(id))
            .toList();

    if (validSelectedIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所选用户都已是管理员或创建者'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 添加所有选中的用户为管理员
    for (final userId in validSelectedIds) {
      _addAdmin(context, ref, userId);
    }
  }

  void _addAdmin(BuildContext context, WidgetRef ref, String userId) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以添加管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // 添加管理员
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.addMeetingAdmin(meeting.id, userId);

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meeting.id));
      // 立即刷新管理员列表
      ref.invalidate(meetingManagersProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理员添加成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加管理员失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAdmin(BuildContext context, WidgetRef ref, String userId) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以移除管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // 获取当前用户ID
      final currentUserId = await ref.read(currentUserIdProvider.future);

      // 构建API请求
      final response = await http
          .delete(
            Uri.parse(
              '${AppConstants.apiBaseUrl}/meeting/admin/remove',
            ).replace(
              queryParameters: {
                'meetingId': meeting.id,
                'userId': userId,
                'currentUserId': currentUserId,
              },
            ),
            headers: HttpUtils.createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // 解析响应
      final responseData = jsonDecode(response.body);

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '移除管理员失败');
      }

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meeting.id));
      // 立即刷新管理员列表
      ref.invalidate(meetingManagersProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理员移除成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除管理员失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 黑名单管理标签页
class _BlacklistTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const _BlacklistTab({required this.meeting, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有参与者（排除已在黑名单中的用户）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
    );

    // 获取管理员列表
    final managersAsync = ref.watch(meetingManagersProvider(meeting.id));

    return Column(
      children: [
        // 黑名单列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (meeting.blacklist.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('黑名单为空', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...meeting.blacklist.map(
                  (userId) => _UserTile(
                    userId: userId,
                    label: '已封禁',
                    canRemove: meeting.canUserManage(currentUserId),
                    onRemove: () {
                      // 从黑名单移除
                      _removeFromBlacklist(context, ref, userId);
                    },
                  ),
                ),
            ],
          ),
        ),

        // 底部添加按钮
        if (meeting.canUserManage(currentUserId))
          participantsAsync.when(
            data: (participants) {
              // 获取管理员ID列表用于过滤
              final adminIds =
                  managersAsync.whenOrNull(
                    data:
                        (managers) =>
                            managers.map((admin) => admin.id).toList(),
                  ) ??
                  [];

              // 过滤掉已在黑名单中的用户和创建者以及管理员
              final availableParticipants =
                  participants
                      .where(
                        (user) =>
                            !meeting.blacklist.contains(user.id) &&
                            user.id != meeting.organizerId &&
                            !adminIds.contains(user.id),
                      )
                      .toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        availableParticipants.isEmpty
                            ? null
                            : () => _showAddToBlacklistDialog(
                              context,
                              ref,
                              availableParticipants,
                            ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: const Text('添加到黑名单'),
                  ),
                ),
              );
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('加载参与者失败: $error')),
                ),
          ),
      ],
    );
  }

  void _showAddToBlacklistDialog(
    BuildContext context,
    WidgetRef ref,
    List<User> availableParticipants,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加到黑名单'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableParticipants.length,
                itemBuilder: (context, index) {
                  final user = availableParticipants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? Text(user.name.substring(0, 1))
                              : null,
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () {
                      Navigator.of(context).pop();
                      _addToBlacklist(context, ref, user.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  void _addToBlacklist(BuildContext context, WidgetRef ref, String userId) {
    // 添加到黑名单
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .addUserToBlacklist(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已将用户添加到黑名单'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('添加到黑名单失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _removeFromBlacklist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    // 从黑名单移除
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .removeUserFromBlacklist(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已将用户从黑名单移除'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('从黑名单移除失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}

/// 用户条目组件
class _UserTile extends HookConsumerWidget {
  final String userId;
  final String label;
  final bool canRemove;
  final VoidCallback? onRemove;

  const _UserTile({
    required this.userId,
    required this.label,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用userNameProvider获取用户名，而不是整个用户信息
    final userNameAsync = ref.watch(userNameProvider(userId));

    return userNameAsync.when(
      data:
          (userName) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLabelColor(label).withAlpha(51),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(color: _getLabelColor(label)),
              ),
            ),
            title: Text(userName),
            subtitle: label == '创建者' ? const Text('会议创建者') : null,
            trailing:
                canRemove && onRemove != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '移除',
                      onPressed: onRemove,
                    )
                    : Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: _getLabelColor(label).withAlpha(25),
                      side: BorderSide(
                        color: _getLabelColor(label).withAlpha(128),
                      ),
                      labelStyle: TextStyle(color: _getLabelColor(label)),
                    ),
          ),
      loading:
          () => ListTile(
            leading: CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('加载中...'),
            trailing: Chip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              backgroundColor: _getLabelColor(label).withAlpha(25),
            ),
          ),
      error:
          (_, __) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLabelColor(label).withAlpha(51),
              child: Text('?', style: TextStyle(color: _getLabelColor(label))),
            ),
            title: Text('用户 $userId'),
            trailing:
                canRemove && onRemove != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '移除',
                      onPressed: onRemove,
                    )
                    : Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: _getLabelColor(label).withAlpha(25),
                      side: BorderSide(
                        color: _getLabelColor(label).withAlpha(128),
                      ),
                      labelStyle: TextStyle(color: _getLabelColor(label)),
                    ),
          ),
    );
  }

  // 根据标签获取颜色
  Color _getLabelColor(String label) {
    switch (label) {
      case '创建者':
        return Colors.orange;
      case '管理员':
        return Colors.blue;
      case '已封禁':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
