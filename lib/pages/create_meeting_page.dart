import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart' as models;
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../widgets/user_selection_dialog.dart';
import '../widgets/meeting/index.dart';

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

    // 处理可见性变更
    void handleVisibilityChanged(models.MeetingVisibility newValue) {
      meetingVisibility.value = newValue;

      // 重置已选用户列表，当可见性从私有变为其他类型时
      if (newValue != models.MeetingVisibility.private) {
        selectedUserIds.value = [];
      }

      // 当切换到私有会议时，禁用密码功能
      if (newValue == models.MeetingVisibility.private) {
        enablePassword.value = false;
        passwordController.clear();
      }
    }

    // 表单验证和提交
    Future<void> submitForm() async {
      bool isValid = formKey.currentState!.validate();

      // 验证会议时间
      if (isValid) {
        isValid = MeetingFormValidators.validateMeetingTime(
          context: context,
          startDate: startDate.value,
          endDate: endDate.value,
        );
      }

      // 验证私有会议的用户选择（如果适用）
      if (isValid &&
          meetingVisibility.value == models.MeetingVisibility.private) {
        // 获取当前用户ID
        final currentUserId = await ref.read(
          currentLoggedInUserIdProvider.future,
        );

        isValid = await MeetingFormValidators.validatePrivateMeetingUsers(
          context: context,
          visibility: meetingVisibility.value,
          selectedUserIds: selectedUserIds.value,
          currentUserId: currentUserId,
          showUserSelectionFunc: showUserSelectionFunc,
        );
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
            // 会议基本信息（标题和地点）
            MeetingFormBaseInfo(
              titleController: titleController,
              locationController: locationController,
            ),
            const SizedBox(height: 16),

            // 会议类型选择
            MeetingTypeSelector(typeController: meetingTypeController),
            const SizedBox(height: 16),

            // 会议可见性选择
            MeetingVisibilitySelector(
              visibilityNotifier: meetingVisibility,
              onVisibilityChanged: handleVisibilityChanged,
            ),
            const SizedBox(height: 16),

            // 用户选择区域 - 仅在私有会议时显示
            if (meetingVisibility.value == models.MeetingVisibility.private)
              Column(
                children: [
                  UsersSelectionCard(
                    selectedUserIds: selectedUserIds.value,
                    onUserSelectionPressed: showUserSelectionFunc,
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // 会议密码设置 - 仅在非私有会议时显示
            if (meetingVisibility.value != models.MeetingVisibility.private)
              Column(
                children: [
                  MeetingPasswordSetting(
                    enablePasswordNotifier: enablePassword,
                    passwordController: passwordController,
                    onEnablePasswordChanged: (value) {
                      enablePassword.value = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // 会议时间选择
            MeetingTimeSelector(
              startDateNotifier: startDate,
              endDateNotifier: endDate,
            ),
            const SizedBox(height: 16),

            // 会议描述
            MeetingDescriptionInput(
              descriptionController: descriptionController,
            ),
            const SizedBox(height: 24),

            // 创建按钮
            MeetingFormSubmitButton(
              formState: createMeetingState,
              onSubmit: submitForm,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
