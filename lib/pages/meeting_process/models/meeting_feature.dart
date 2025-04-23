import 'package:flutter/material.dart';

/// 会议功能选项模型
class MeetingFeature {
  final IconData icon;
  final String label;
  final Color color;

  const MeetingFeature({
    required this.icon,
    required this.label,
    required this.color,
  });
}
