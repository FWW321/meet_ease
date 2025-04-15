import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
            onSubmitted: (_) => _validatePassword(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValidating ? null : _validatePassword,
          child: const Text('加入会议'),
        ),
      ],
    );
  }

  Future<void> _validatePassword() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorMessage = '请输入密码';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final validator = ref.read(
        validateMeetingPasswordProvider(widget.meetingId).notifier,
      );
      final isValid = await validator.validate(password);

      if (isValid) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = '密码错误，请重试';
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '验证失败: $e';
        _isValidating = false;
      });
    }
  }
}
