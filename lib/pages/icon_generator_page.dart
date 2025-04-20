import 'dart:io';
import 'package:flutter/material.dart';
import '../tools/icon_generator.dart';

/// 图标生成页面
/// 允许用户生成应用图标
class IconGeneratorPage extends StatefulWidget {
  const IconGeneratorPage({super.key});

  @override
  State<IconGeneratorPage> createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  bool _isGenerating = false;
  bool _isGenerated = false;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生成应用图标')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('点击下方按钮生成会议应用图标', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              if (_isGenerated &&
                  File('assets/images/app_icon.png').existsSync())
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File('assets/images/app_icon.png'),
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              if (_isGenerating)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _generateIcon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text('生成图标'),
                ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    color: _isGenerated ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              if (_isGenerated) ...[
                const SizedBox(height: 30),
                const Text(
                  '下一步：\n1. 在终端运行: flutter pub run flutter_launcher_icons\n2. 重新构建应用以应用新图标',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateIcon() async {
    try {
      setState(() {
        _isGenerating = true;
        _message = '正在生成图标...';
      });

      await IconGenerator.generateMeetingIcon();

      setState(() {
        _isGenerating = false;
        _isGenerated = true;
        _message = '图标生成成功！';
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _message = '图标生成失败: $e';
      });
    }
  }
}
