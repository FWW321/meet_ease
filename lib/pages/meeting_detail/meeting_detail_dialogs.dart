import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../constants/app_constants.dart';

/// 显示取消会议确认对话框
void showCancelConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  String creatorId,
) {
  showDialog(
    context: context,
    builder: (context) => _CancelMeetingDialog(creatorId: creatorId),
  );
}

/// 取消会议对话框组件
class _CancelMeetingDialog extends ConsumerWidget {
  final String creatorId;

  const _CancelMeetingDialog({required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从路由中获取meetingId
    final settings = ModalRoute.of(context)?.settings;
    final meetingId =
        settings?.arguments is String ? settings!.arguments as String : '';

    return AlertDialog(
      title: const Text('取消会议'),
      content: const Text('确定要取消此会议吗？此操作不可撤销，所有参会者将收到会议取消的通知。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            // 显示加载指示器
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            try {
              // 调用取消会议服务
              final meetingService = ref.read(meetingServiceProvider);
              await meetingService.cancelMeeting(meetingId, creatorId);

              // 刷新会议详情
              ref.invalidate(meetingDetailProvider(meetingId));

              if (context.mounted) {
                // 关闭加载指示器
                Navigator.of(context).pop();

                // 显示成功提示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('会议已成功取消'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                // 关闭加载指示器
                Navigator.of(context).pop();

                // 显示错误提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('取消会议失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('确定取消'),
        ),
      ],
    );
  }
}

/// 显示请假申请对话框
void showLeaveRequestDialog(
  BuildContext context,
  WidgetRef ref,
  Meeting meeting,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _LeaveRequestDialog(meeting: meeting),
  );
}

/// 请假申请对话框组件
class _LeaveRequestDialog extends ConsumerStatefulWidget {
  final Meeting meeting;

  const _LeaveRequestDialog({required this.meeting});

  @override
  ConsumerState<_LeaveRequestDialog> createState() =>
      _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends ConsumerState<_LeaveRequestDialog> {
  final reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusL),
                  topRight: Radius.circular(AppConstants.radiusL),
                ),
              ),
              child: Text(
                '申请请假',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: '简要说明您的请假原因...',
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(
                        AppConstants.paddingM,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            // 按钮
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.paddingL,
                right: AppConstants.paddingL,
                bottom: AppConstants.paddingL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按钮
                  TextButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingL,
                        vertical: AppConstants.paddingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  // 提交按钮
                  ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => _submitLeaveRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingL,
                        vertical: AppConstants.paddingM,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : const Text('提交申请'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLeaveRequest(BuildContext context) async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入请假理由'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 调用请假服务
      final meetingService = ref.read(meetingServiceProvider);
      final currentUserId = await ref.read(currentUserIdProvider.future);

      if (currentUserId == null) {
        throw Exception('用户未登录');
      }

      final result = await meetingService.submitLeaveRequest(
        currentUserId,
        widget.meeting.id,
        reason,
      );

      if (!context.mounted) {
        return;
      }

      // 关闭对话框
      Navigator.of(context).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(child: Text('请假申请已成功提交')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          margin: const EdgeInsets.all(AppConstants.paddingM),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('提交请假申请失败: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          margin: const EdgeInsets.all(AppConstants.paddingM),
        ),
      );
    }
  }
}
