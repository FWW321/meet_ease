import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 会议图标生成工具
/// 使用Flutter原生功能生成一个简单的会议图标
/// 不依赖任何外部资源
class IconGenerator {
  /// 生成会议图标并保存到指定路径
  static Future<void> generateMeetingIcon() async {
    // 创建一个记录器以绘制图标
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 图标尺寸 (1024x1024 适合各种尺寸的缩放)
    const size = Size(1024, 1024);

    // 绘制渐变背景
    final bgPaint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0175C2), Color(0xFF13B9FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(200), // 圆角半径
      ),
      bgPaint,
    );

    // 绘制会议图标元素
    _drawMeetingElements(canvas, size);

    // 完成绘制并创建图像
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // 确保目录存在
    final directory = Directory('assets/images');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // 保存图像到文件
    final file = File('assets/images/app_icon.png');
    await file.writeAsBytes(pngBytes);

    print('图标已生成并保存到: ${file.path}');
  }

  /// 绘制会议相关的图形元素
  static void _drawMeetingElements(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制一个简单的会议桌图形 (圆形)
    final tablePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      size.width * 0.35, // 桌子半径
      tablePaint,
    );

    // 桌子边框
    final borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15;

    canvas.drawCircle(
      center,
      size.width * 0.35 + 10, // 边框比桌子稍大
      borderPaint,
    );

    // 绘制人物图标 (围绕桌子)
    const personCount = 6;
    const radius = 0.32; // 人物距离中心点的半径比例

    for (int i = 0; i < personCount; i++) {
      final angle = 2 * 3.14159 * i / personCount;
      final personCenter = Offset(
        center.dx + size.width * radius * cos(angle),
        center.dy + size.width * radius * sin(angle),
      );

      // 绘制人物头像
      final personPaint =
          Paint()
            ..color = const Color(0xFF023E8A)
            ..style = PaintingStyle.fill;

      // 头部
      canvas.drawCircle(
        Offset(personCenter.dx, personCenter.dy - size.width * 0.04),
        size.width * 0.05,
        personPaint,
      );

      // 身体
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              personCenter.dx,
              personCenter.dy + size.width * 0.05,
            ),
            width: size.width * 0.08,
            height: size.width * 0.1,
          ),
          const Radius.circular(20),
        ),
        personPaint,
      );
    }

    // 绘制中心文本或图标
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ME',
        style: TextStyle(
          color: Color(0xFF023E8A),
          fontSize: 180,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}
