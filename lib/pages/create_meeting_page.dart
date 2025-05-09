import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart' as models;
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../widgets/user_selection_dialog.dart';
import '../widgets/meeting/index.dart';
import '../constants/app_constants.dart';

class CreateMeetingPage extends HookConsumerWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 表单字段控制器
    final titleController = useTextEditingController();
    final locationController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final passwordController = useTextEditingController();
    final meetingTypeController = useTextEditingController();

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
            SnackBar(
              content: const Text('会议创建成功'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
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
      appBar: AppBar(
        title: const Text('创建会议'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Theme(
        // 创建一个局部主题，只影响这个页面的输入框样式
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor:
                colorScheme.brightness == Brightness.light
                    ? Colors.white
                    : colorScheme.surfaceVariant.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              borderSide: BorderSide(color: colorScheme.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              borderSide: BorderSide(color: colorScheme.error, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hoverColor: colorScheme.primaryContainer.withOpacity(0.08),
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.surface, colorScheme.surfaceContainer],
            ),
          ),
          child: Form(
            key: formKey,
            child: ListView(
              controller: scrollController,
              key: const PageStorageKey<String>('createMeetingPageScrollView'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingL,
                vertical: AppConstants.paddingM,
              ),
              children: [
                // 页面标题和提示
                _buildPageHeader(theme),
                const SizedBox(height: AppConstants.paddingL),

                // 会议基本信息卡片
                _buildFormCard(
                  context: context,
                  title: '基本信息',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      // 会议基本信息（标题和地点）
                      MeetingFormBaseInfo(
                        titleController: titleController,
                        locationController: locationController,
                      ),
                      const SizedBox(height: AppConstants.paddingM),

                      // 会议类型选择
                      MeetingTypeSelector(
                        typeController: meetingTypeController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // 会议设置卡片
                _buildFormCard(
                  context: context,
                  title: '会议设置',
                  icon: Icons.settings_outlined,
                  child: Column(
                    children: [
                      // 会议可见性选择
                      MeetingVisibilitySelector(
                        visibilityNotifier: meetingVisibility,
                        onVisibilityChanged: handleVisibilityChanged,
                      ),
                      const SizedBox(height: AppConstants.paddingM),

                      // 用户选择区域 - 仅在私有会议时显示
                      if (meetingVisibility.value ==
                          models.MeetingVisibility.private)
                        Column(
                          children: [
                            UsersSelectionCard(
                              selectedUserIds: selectedUserIds.value,
                              onUserSelectionPressed: showUserSelectionFunc,
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                          ],
                        ),

                      // 会议密码设置 - 仅在非私有会议时显示
                      if (meetingVisibility.value !=
                          models.MeetingVisibility.private)
                        Column(
                          children: [
                            MeetingPasswordSetting(
                              enablePasswordNotifier: enablePassword,
                              passwordController: passwordController,
                              onEnablePasswordChanged: (value) {
                                enablePassword.value = value;
                              },
                            ),
                            const SizedBox(height: AppConstants.paddingM),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // 会议时间卡片
                _buildFormCard(
                  context: context,
                  title: '会议时间',
                  icon: Icons.access_time,
                  child: MeetingTimeSelector(
                    startDateNotifier: startDate,
                    endDateNotifier: endDate,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // 会议详情卡片
                _buildFormCard(
                  context: context,
                  title: '会议详情',
                  icon: Icons.description_outlined,
                  child: MeetingDescriptionInput(
                    descriptionController: descriptionController,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXL),

                // 创建按钮
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: createMeetingState.isLoading ? null : submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: colorScheme.primary.withOpacity(
                        0.6,
                      ),
                      disabledForegroundColor: colorScheme.onPrimary
                          .withOpacity(0.7),
                      elevation: 2,
                      shadowColor: colorScheme.shadow.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    child:
                        createMeetingState.isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              '创建会议',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 页面标题和提示文字
  Widget _buildPageHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '创建新会议',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Text(
          '填写以下信息创建您的会议，带*号的为必填项',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // 表单卡片组件
  Widget _buildFormCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      color:
          theme.colorScheme.brightness == Brightness.light
              ? Colors.white
              : theme.colorScheme.surfaceVariant.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Divider(
              height: AppConstants.paddingL,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            // 卡片内容
            child,
          ],
        ),
      ),
    );
  }
}
