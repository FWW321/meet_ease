import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/meeting.dart';

/// 会议类型选择组件
class MeetingTypeSelector extends StatelessWidget {
  final TextEditingController typeController;

  const MeetingTypeSelector({super.key, required this.typeController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 预设会议类型选项
    final meetingTypes = [
      {'type': MeetingType.regular, 'label': '常规会议', 'icon': Icons.event_note},
      {'type': MeetingType.training, 'label': '培训会议', 'icon': Icons.school},
      {
        'type': MeetingType.interview,
        'label': '面试会议',
        'icon': Icons.person_search,
      },
      {'type': MeetingType.other, 'label': '其他', 'icon': Icons.more_horiz},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 会议类型输入框
        TextFormField(
          controller: typeController,
          decoration: InputDecoration(
            labelText: '会议类型 *',
            hintText: '如：常规会议、培训会议、面试会议等',
            prefixIcon: Icon(
              Icons.category_outlined,
              color: theme.colorScheme.primary,
            ),
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
        ),

        const SizedBox(height: AppConstants.paddingS),

        // 类型快速选择提示
        Text(
          '快速选择:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: AppConstants.paddingXS),

        // 类型选择区域
        Wrap(
          spacing: AppConstants.paddingS,
          children:
              meetingTypes.map((type) {
                return ActionChip(
                  avatar: Icon(
                    type['icon'] as IconData,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(type['label'] as String),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withAlpha(179),
                  onPressed: () {
                    typeController.text = type['label'] as String;
                    // 强制刷新
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
        ),
      ],
    );
  }
}
