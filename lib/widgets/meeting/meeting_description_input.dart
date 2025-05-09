import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 会议描述输入组件
class MeetingDescriptionInput extends StatelessWidget {
  final TextEditingController descriptionController;

  const MeetingDescriptionInput({
    super.key,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: descriptionController,
          maxLength: 500, // 限制描述最大长度
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            labelText: '会议描述',
            hintText: '描述会议目的、议程或其他重要信息',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            suffixIcon:
                descriptionController.text.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          descriptionController.clear();
                          // 强制刷新
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    )
                    : null,
          ),
          validator: (value) {
            if (value != null && value.length > 500) {
              return '会议描述不能超过500个字符';
            }
            return null;
          },
          onChanged: (value) {
            // 强制刷新
            (context as Element).markNeedsBuild();
          },
        ),

        const SizedBox(height: AppConstants.paddingS),

        // 添加说明文字
        if (descriptionController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '添加会议描述可以让参与者更好地了解会议内容',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
