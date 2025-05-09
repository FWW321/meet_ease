import 'package:flutter/material.dart';

/// 会议类型选择组件
class MeetingTypeSelector extends StatelessWidget {
  final TextEditingController typeController;

  const MeetingTypeSelector({super.key, required this.typeController});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: typeController,
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
    );
  }
}
