import 'package:flutter/material.dart';
import '../../models/meeting.dart';
import '../../utils/meeting_utils.dart' as meeting_utils;
import '../../constants/app_constants.dart';

/// 会议可见性选择组件
class MeetingVisibilitySelector extends StatelessWidget {
  final ValueNotifier<MeetingVisibility> visibilityNotifier;
  final Function(MeetingVisibility) onVisibilityChanged;

  const MeetingVisibilitySelector({
    super.key,
    required this.visibilityNotifier,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 可见性对应的图标和描述
    final visibilityInfo = {
      MeetingVisibility.public: {
        'icon': Icons.public,
        'description': '所有人可见并可参加会议',
        'color': Colors.green,
      },
      MeetingVisibility.private: {
        'icon': Icons.lock,
        'description': '仅特定用户可查看和参加会议',
        'color': Colors.orange,
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 下拉选择器
        DropdownButtonFormField<MeetingVisibility>(
          value: visibilityNotifier.value,
          decoration: const InputDecoration(
            labelText: '会议可见性 *',
            // 移除前缀图标，避免重复
          ),
          onChanged: (newValue) {
            if (newValue != null) {
              onVisibilityChanged(newValue);
            }
          },
          items:
              MeetingVisibility.values.map((visibility) {
                return DropdownMenuItem<MeetingVisibility>(
                  value: visibility,
                  child: Row(
                    children: [
                      Icon(
                        visibilityInfo[visibility]!['icon'] as IconData,
                        color: visibilityInfo[visibility]!['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(meeting_utils.getMeetingVisibilityText(visibility)),
                    ],
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: AppConstants.paddingS),

        // 可见性说明
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(color: theme.colorScheme.outline.withAlpha(26)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  visibilityInfo[visibilityNotifier.value]!['description']
                      as String,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
