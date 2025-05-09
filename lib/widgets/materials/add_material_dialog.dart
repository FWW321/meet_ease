import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/meeting_material.dart' as models;
import '../../constants/app_constants.dart';
import '../../providers/meeting_process_providers.dart';
import '../../utils/http_utils.dart';
import 'material_utils.dart';

/// 添加资料对话框组件
class AddMaterialDialog extends ConsumerStatefulWidget {
  final String meetingId;

  const AddMaterialDialog({required this.meetingId, super.key});

  @override
  AddMaterialDialogState createState() => AddMaterialDialogState();
}

class AddMaterialDialogState extends ConsumerState<AddMaterialDialog> {
  models.MaterialType selectedType = models.MaterialType.document;
  PlatformFile? selectedFile;
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加资料'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<models.MaterialType>(
              value: selectedType,
              decoration: const InputDecoration(labelText: '资料类型'),
              items: [
                DropdownMenuItem(
                  value: models.MaterialType.document,
                  child: Row(
                    children: [
                      Icon(
                        MaterialUtils.getMaterialTypeIcon(
                          models.MaterialType.document,
                        ),
                        color: MaterialUtils.getMaterialTypeColor(
                          models.MaterialType.document,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('文档'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: models.MaterialType.image,
                  child: Row(
                    children: [
                      Icon(
                        MaterialUtils.getMaterialTypeIcon(
                          models.MaterialType.image,
                        ),
                        color: MaterialUtils.getMaterialTypeColor(
                          models.MaterialType.image,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('图片'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: models.MaterialType.video,
                  child: Row(
                    children: [
                      Icon(
                        MaterialUtils.getMaterialTypeIcon(
                          models.MaterialType.video,
                        ),
                        color: MaterialUtils.getMaterialTypeColor(
                          models.MaterialType.video,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('视频'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: models.MaterialType.presentation,
                  child: Row(
                    children: [
                      Icon(
                        MaterialUtils.getMaterialTypeIcon(
                          models.MaterialType.presentation,
                        ),
                        color: MaterialUtils.getMaterialTypeColor(
                          models.MaterialType.presentation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('演示文稿'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: models.MaterialType.other,
                  child: Row(
                    children: [
                      Icon(
                        MaterialUtils.getMaterialTypeIcon(
                          models.MaterialType.other,
                        ),
                        color: MaterialUtils.getMaterialTypeColor(
                          models.MaterialType.other,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('其他'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('选择文件'),
                  ),
                ),
              ],
            ),
            if (fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已选择: $fileName',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: selectedFile == null ? null : _uploadFile,
          child: const Text('上传'),
        ),
      ],
    );
  }

  // 选择文件
  Future<void> _pickFile() async {
    // 打开文件选择器
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first;
        fileName = selectedFile!.name;

        // 根据文件扩展名自动选择类型
        final extension = fileName!.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          selectedType = models.MaterialType.image;
        } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
          selectedType = models.MaterialType.video;
        } else if (['ppt', 'pptx', 'key'].contains(extension)) {
          selectedType = models.MaterialType.presentation;
        } else if ([
          'doc',
          'docx',
          'pdf',
          'txt',
          'xls',
          'xlsx',
        ].contains(extension)) {
          selectedType = models.MaterialType.document;
        } else {
          selectedType = models.MaterialType.other;
        }
      });
    }
  }

  // 上传文件
  Future<void> _uploadFile() async {
    if (fileName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择文件')));
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 获取当前用户信息
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      String uploaderId = '';
      String uploaderName = '';

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        uploaderId = userData['id'] ?? '';
        uploaderName = userData['name'] ?? '';
      }

      // 直接创建HTTP客户端，调用上传文件的API
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/file/upload'),
      );

      // 添加文件
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path!,
          filename: selectedFile!.name,
        ),
      );

      // 添加请求头
      request.headers.addAll(HttpUtils.createHeaders());

      // 添加其他字段
      request.fields['meetingId'] = widget.meetingId;
      request.fields['uploaderId'] = uploaderId;
      request.fields['uploaderName'] = uploaderName;
      request.fields['fileName'] = fileName!;

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 确保widget仍然挂载在树上
      if (!mounted) return;

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        if (responseData['code'] == 200) {
          // 上传成功后刷新列表
          ref.invalidate(meetingMaterialsNotifierProvider(widget.meetingId));

          // 关闭加载指示器
          Navigator.of(context).pop();

          // 关闭对话框
          Navigator.of(context).pop();

          // 显示成功消息
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('资料上传成功')));
        } else {
          // 关闭加载指示器
          Navigator.of(context).pop();

          final message = responseData['message'] ?? '资料上传失败';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        // 关闭加载指示器
        Navigator.of(context).pop();

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: ${response.statusCode} - ${response.body}'),
          ),
        );
      }
    } catch (e) {
      // 确保widget仍然挂载在树上
      if (!mounted) return;

      // 关闭加载指示器
      Navigator.of(context).pop();

      // 显示错误消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
    }
  }
}
