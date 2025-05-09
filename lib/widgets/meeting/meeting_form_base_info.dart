import 'package:flutter/material.dart';

/// 会议基础信息表单组件
class MeetingFormBaseInfo extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController locationController;

  const MeetingFormBaseInfo({
    super.key,
    required this.titleController,
    required this.locationController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 会议标题
        TextFormField(
          controller: titleController,
          maxLength: 50, // 限制标题最大长度为50个字符
          decoration: const InputDecoration(
            labelText: '会议标题',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
            counterText: '', // 隐藏内置的字符计数
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入会议标题';
            }
            if (value.trim().length < 3) {
              return '会议标题至少需要3个字符';
            }
            if (value.trim().length > 50) {
              return '会议标题不能超过50个字符';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 会议地点
        TextFormField(
          controller: locationController,
          maxLength: 100, // 限制地点最大长度
          decoration: const InputDecoration(
            labelText: '会议地点',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入会议地点';
            }
            if (value.trim().length < 2) {
              return '会议地点至少需要2个字符';
            }
            return null;
          },
        ),
      ],
    );
  }
}
