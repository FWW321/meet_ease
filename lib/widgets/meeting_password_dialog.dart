import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async'; 
import '../providers/meeting_providers.dart';

/// 会议密码验证对话框
class MeetingPasswordDialog extends ConsumerStatefulWidget {
  final String meetingId;

  const MeetingPasswordDialog({super.key, required this.meetingId});

  @override
  ConsumerState<MeetingPasswordDialog> createState() =>
      _MeetingPasswordDialogState();
}

class _MeetingPasswordDialogState extends ConsumerState<MeetingPasswordDialog> {
  final passwordController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  // 添加验证器缓存
  ValidateMeetingPassword? _cachedValidator;

  @override
  void initState() {
    super.initState();
    // 预先获取验证器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cachedValidator = ref.read(
          validateMeetingPasswordProvider(widget.meetingId).notifier,
        );
      }
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('会议需要密码'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('请输入会议密码以参加此会议'),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '会议密码',
              errorText: _errorMessage,
              suffixIcon:
                  _isValidating
                      ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.lock_outline),
            ),
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _handleValidatePassword(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValidating ? null : _handleValidatePassword,
          child: const Text('加入会议'),
        ),
      ],
    );
  }

  // 完全重写的密码验证处理方法
  Future<void> _handleValidatePassword() async {
    final password = passwordController.text.trim();

    // 空密码检查
    if (password.isEmpty) {
      setState(() {
        _errorMessage = '请输入密码';
      });
      return;
    }

    // 防止重复验证
    if (_isValidating) {
      return;
    }

    // 设置验证中状态
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // 获取缓存的验证器或创建新的
      final validator =
          _cachedValidator ??
          ref.read(validateMeetingPasswordProvider(widget.meetingId).notifier);

      // 记录调用开始
      print('开始验证密码: ${DateTime.now()}');

      // 执行验证
      final result = await validator!.validate(password);

      // 记录调用结束
      print('密码验证完成: ${DateTime.now()}, 结果: $result');

      // 检查组件状态
      if (!mounted) return;

      // 处理结果
      if (result) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = '密码错误，请重试';
          _isValidating = false;
        });
      }
    } catch (e) {
      // 记录并处理错误
      print('密码验证异常: $e');

      if (!mounted) return;

      // 错误分类处理
      final errorMessage = _getErrorMessage(e);

      setState(() {
        _errorMessage = errorMessage;
        _isValidating = false;
      });
    }
  }

  // 辅助方法：获取友好的错误信息
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('timeout') || errorString.contains('超时')) {
      return '验证超时，请稍后再试';
    } else if (errorString.contains('Connection') ||
        errorString.contains('network')) {
      return '网络连接失败，请检查网络';
    } else if (errorString.contains('Future already completed')) {
      return '系统处理冲突，请重新尝试';
    } else if (errorString.contains('会议不存在') ||
        errorString.contains('not found')) {
      return '找不到此会议，请检查会议ID';
    } else {
      // 限制错误信息长度
      return '验证失败: ${errorString.length > 20 ? '${errorString.substring(0, 20)}...' : errorString}';
    }
  }
}
