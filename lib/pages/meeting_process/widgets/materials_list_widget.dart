import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../widgets/materials_list_widget.dart' as original;

/// 会议资料列表组件
class MaterialsListWidget extends ConsumerWidget {
  final String meetingId;
  final bool isReadOnly;

  const MaterialsListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用原始会议资料列表组件
    return original.MaterialsListWidget(
      meetingId: meetingId,
      isReadOnly: isReadOnly,
    );
  }
}
