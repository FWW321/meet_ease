import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// 会议表单提交按钮组件
class MeetingFormSubmitButton extends ConsumerWidget {
  final AsyncValue<dynamic> formState;
  final VoidCallback onSubmit;

  const MeetingFormSubmitButton({
    super.key,
    required this.formState,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: formState.isLoading ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child:
          formState.isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Text('创建会议'),
    );
  }
}
