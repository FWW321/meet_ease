import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 会议标题
        TextFormField(
          controller: titleController,
          maxLength: 50, // 限制标题最大长度为50个字符
          decoration: InputDecoration(
            labelText: '会议标题 *',
            hintText: '输入会议标题（最多50个字符）',
            prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
            counterText: '', // 隐藏内置的字符计数
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                '${titleController.text.length}/50',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
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
          onChanged: (value) {
            // 强制刷新以更新字符计数器
            (context as Element).markNeedsBuild();
          },
        ),
        const SizedBox(height: AppConstants.paddingM),

        // 会议地点
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: '会议地点 *',
            hintText: '输入会议地点或线上会议链接',
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入会议地点';
            }
            return null;
          },
        ),
      ],
    );
  }
}
