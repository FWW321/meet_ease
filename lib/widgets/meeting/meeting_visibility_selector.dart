import 'package:flutter/material.dart';
import '../../models/meeting.dart';
import '../../utils/meeting_utils.dart' as meeting_utils;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: '会议可见性',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.visibility),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MeetingVisibility>(
              value: visibilityNotifier.value,
              isExpanded: true,
              onChanged: (newValue) {
                if (newValue != null) {
                  onVisibilityChanged(newValue);
                }
              },
              items:
                  MeetingVisibility.values.map((visibility) {
                    return DropdownMenuItem<MeetingVisibility>(
                      value: visibility,
                      child: Text(
                        meeting_utils.getMeetingVisibilityText(visibility),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 不同可见性的提示信息
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            meeting_utils.getMeetingVisibilityDescription(
              visibilityNotifier.value,
            ),
            style: TextStyle(
              color: _getVisibilityColor(visibilityNotifier.value),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // 获取会议可见性的颜色
  Color _getVisibilityColor(MeetingVisibility visibility) {
    switch (visibility) {
      case MeetingVisibility.public:
        return Colors.blue;
      case MeetingVisibility.private:
        return Colors.red;
    }
  }
}
