import 'package:flutter/material.dart';

/// 录音状态指示器组件
class RecordingIndicator extends StatelessWidget {
  final int recordDuration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const RecordingIndicator({
    required this.recordDuration,
    required this.onCancel,
    required this.onSend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // 动画闪烁的麦克风图标
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Icon(
                Icons.mic,
                color: Color.fromARGB(
                  (value * 255).round(),
                  Colors.red.r.toInt(),
                  Colors.red.g.toInt(),
                  Colors.red.b.toInt(),
                ),
                size: 24,
              );
            },
          ),
          const SizedBox(width: 8),

          // 录音时长
          Text(
            '录音中 ${_formatDuration(Duration(seconds: recordDuration))}',
            style: TextStyle(color: Colors.red.shade700),
          ),
          const Spacer(),

          // 取消录音按钮
          TextButton(onPressed: onCancel, child: const Text('取消')),

          // 发送录音按钮
          ElevatedButton(
            onPressed: onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
