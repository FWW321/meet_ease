import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';

/// 会议设置页面 - 仅会议创建者和管理员可访问
class MeetingSettingsPage extends HookConsumerWidget {
  final String meetingId;
  final String currentUserId;

  const MeetingSettingsPage({
    required this.meetingId,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

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
          if (meeting.status == MeetingStatus.completed ||
              meeting.status == MeetingStatus.cancelled) {
            return Center(
              child: Text('无法修改${getMeetingStatusText(meeting.status)}的会议设置'),
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
                      color: Colors.black.withOpacity(0.05),
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

  const _MeetingInfoTab({
    required this.meeting,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取会议ID
    final meetingId = meeting.id;

    // 标题控制器
    final titleController = useTextEditingController(text: meeting.title);
    final descriptionController = useTextEditingController(
      text: meeting.description ?? '',
    );
    final locationController = useTextEditingController(text: meeting.location);

    // 密码相关状态
    final passwordController = useTextEditingController(
      text: meeting.password ?? '',
    );
    final enablePassword = useState(
      meeting.password != null && meeting.password!.isNotEmpty,
    );
    final isUpdatingPassword = useState(false);
    final passwordError = useState<String?>(null);

    // 日期选择
    final startTime = useState(meeting.startTime);
    final endTime = useState(meeting.endTime);

    // 会议类型
    final meetingType = useState(meeting.type);

    // 构建密码设置UI
    Widget buildPasswordSettings() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, color: Colors.blue),
              const SizedBox(width: 8.0),
              const Text(
                '会议密码',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              const Spacer(),
              Switch(
                value: enablePassword.value,
                onChanged: (value) {
                  enablePassword.value = value;
                  if (!value) {
                    passwordController.clear();
                    passwordError.value = null;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (enablePassword.value) ...[
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: '设置密码',
                hintText: '参会者需要输入此密码才能加入会议',
                border: const OutlineInputBorder(),
                errorText: passwordError.value,
                suffixIcon:
                    isUpdatingPassword.value
                        ? Container(
                          width: 20.0,
                          height: 20.0,
                          padding: const EdgeInsets.all(8.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        )
                        : IconButton(
                          icon: const Icon(Icons.check_circle),
                          color: Colors.green,
                          onPressed:
                              () => _updatePassword(
                                context,
                                ref,
                                passwordController,
                                isUpdatingPassword,
                                passwordError,
                              ),
                        ),
              ),
              obscureText: true,
              onSubmitted:
                  (_) => _updatePassword(
                    context,
                    ref,
                    passwordController,
                    isUpdatingPassword,
                    passwordError,
                  ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              '启用密码后，参会者需要输入正确的密码才能加入会议',
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
          ] else ...[
            const Text(
              '不启用密码，所有参会者可直接加入会议',
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
            if (meeting.password != null && meeting.password!.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, size: 18.0),
                label: const Text('删除现有密码'),
                onPressed:
                    () => _removePassword(
                      context,
                      ref,
                      enablePassword,
                      passwordController,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                ),
              ),
            ],
          ],
        ],
      );
    }

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

                // 会议密码设置
                buildPasswordSettings(),
                const Divider(height: 24.0),

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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateTime.value,
      firstDate: isStart ? DateTime.now() : (meeting.startTime),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
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

    // 更新会议信息
    final meetingService = ref.read(meetingServiceProvider);

    meetingService
        .updateMeeting(
          meeting.id,
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
          type: type,
        )
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('会议信息更新成功'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新会议信息失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  // 更新会议密码
  Future<void> _updatePassword(
    BuildContext context,
    WidgetRef ref,
    TextEditingController passwordController,
    ValueNotifier<bool> isUpdatingPassword,
    ValueNotifier<String?> passwordError,
  ) async {
    final password = passwordController.text.trim();
    final meetingId = meeting.id;

    // 验证密码
    if (password.isEmpty) {
      passwordError.value = '请输入会议密码';
      return;
    }

    // 重置错误信息
    passwordError.value = null;

    // 设置更新状态
    isUpdatingPassword.value = true;

    try {
      // 更新会议信息，添加密码
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.updateMeetingPassword(meetingId, password);

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会议密码已更新'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meetingId));
    } catch (e) {
      // 显示错误消息
      passwordError.value = '更新密码失败: $e';
    } finally {
      // 重置状态
      isUpdatingPassword.value = false;
    }
  }

  // 删除会议密码
  Future<void> _removePassword(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> enablePassword,
    TextEditingController passwordController,
  ) async {
    final meetingId = meeting.id;

    try {
      // 更新会议信息，删除密码
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.updateMeetingPassword(meetingId, null);

      // 更新本地状态
      enablePassword.value = false;
      passwordController.clear();

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会议密码已删除'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meetingId));
    } catch (e) {
      // 显示错误消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除密码失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// 管理员管理标签页
class _AdminsTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const _AdminsTab({
    required this.meeting,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有参与者（排除创建者和已有管理员）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
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

              const Divider(),

              // 现有管理员列表
              if (meeting.admins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      '尚未添加管理员',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...meeting.admins.map(
                  (adminId) => _UserTile(
                    userId: adminId,
                    label: '管理员',
                    canRemove: meeting.isCreatorOnly(currentUserId),
                    onRemove: () {
                      // 移除管理员
                      _removeAdmin(context, ref, adminId);
                    },
                  ),
                ),
            ],
          ),
        ),

        // 底部添加按钮，只有创建者可以添加管理员
        if (meeting.isCreatorOnly(currentUserId))
          participantsAsync.when(
            data: (participants) {
              // 过滤掉创建者和现有管理员
              final availableParticipants =
                  participants
                      .where(
                        (user) =>
                            user.id != meeting.organizerId &&
                            !meeting.admins.contains(user.id),
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
                            : () => _showAddAdminDialog(
                              context,
                              ref,
                              availableParticipants,
                            ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: const Text('添加管理员'),
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

  void _showAddAdminDialog(
    BuildContext context,
    WidgetRef ref,
    List<User> availableParticipants,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加管理员'),
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
                      _addAdmin(context, ref, user.id);
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

  void _addAdmin(BuildContext context, WidgetRef ref, String userId) {
    // 添加管理员
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .addMeetingAdmin(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('管理员添加成功'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('添加管理员失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void _removeAdmin(BuildContext context, WidgetRef ref, String userId) {
    // 移除管理员
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .removeMeetingAdmin(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('管理员移除成功'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('移除管理员失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
}

/// 黑名单管理标签页
class _BlacklistTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const _BlacklistTab({
    required this.meeting,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有参与者（排除已在黑名单中的用户）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
    );

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
              // 过滤掉已在黑名单中的用户和创建者
              final availableParticipants =
                  participants
                      .where(
                        (user) =>
                            !meeting.blacklist.contains(user.id) &&
                            user.id != meeting.organizerId &&
                            !meeting.admins.contains(user.id),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已将用户添加到黑名单'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('添加到黑名单失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已将用户从黑名单移除'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('从黑名单移除失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取用户信息
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data:
          (user) => ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child:
                  user.avatarUrl == null
                      ? Text(user.name.substring(0, 1))
                      : null,
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing:
                canRemove && onRemove != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '移除',
                      onPressed: onRemove,
                    )
                    : Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.grey.shade100,
                    ),
          ),
      loading:
          () => const ListTile(
            leading: CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('加载中...'),
          ),
      error:
          (error, stackTrace) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.error)),
            title: Text('加载失败'),
            subtitle: Text('$error'),
          ),
    );
  }
}
