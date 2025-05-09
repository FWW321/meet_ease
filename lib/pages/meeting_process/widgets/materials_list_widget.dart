import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../widgets/materials/materials_list_widget.dart'
    as material_widgets;

/// 会议过程页面的资料列表组件
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
    // 使用重构后的会议资料列表组件
    return material_widgets.MaterialsListWidget(
      meetingId: meetingId,
      isReadOnly: isReadOnly,
    );
  }
}
