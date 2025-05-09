import 'package:flutter/material.dart';

/// 会议描述输入组件
class MeetingDescriptionInput extends StatelessWidget {
  final TextEditingController descriptionController;

  const MeetingDescriptionInput({
    super.key,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
    );
  }
}
