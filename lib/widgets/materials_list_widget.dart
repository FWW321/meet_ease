import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/meeting_material.dart' as models;
import '../providers/meeting_process_providers.dart';
import '../constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show File, Platform, Process, Directory;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/http_utils.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final materialsAsync = ref.watch(
      meetingMaterialsNotifierProvider(meetingId),
    );

    return materialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '获取会议资料失败\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  TextSpan(text: error.toString()),
                ],
              ),
            ),
          ),
      data: (materials) {
        if (materials.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('暂无会议资料'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddMaterialDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('添加资料'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 标题和按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('会议资料', style: Theme.of(context).textTheme.titleLarge),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMaterialDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('添加资料'),
                  ),
                ],
              ),
            ),

            // 资料列表
            Expanded(
              child: ListView.builder(
                itemCount: materials.items.length,
                itemBuilder: (context, index) {
                  final material = materials.items[index];
                  return _buildMaterialItem(context, material, ref);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 检查文件是否已下载
  Future<bool> _isFileDownloaded(models.MaterialItem material) async {
    try {
      // 在Web平台上总是返回false
      if (kIsWeb) {
        return false;
      }

      // 获取下载路径
      final String downloadPath = await _getDownloadPath();

      // 检查文件是否存在
      final String filePath = '$downloadPath/${material.title}';
      final file = File(filePath);

      // 检查同名带编号的文件
      if (!await file.exists()) {
        // 分离文件名和扩展名
        final int lastDotIndex = material.title.lastIndexOf('.');
        String nameWithoutExtension;
        String extension;

        if (lastDotIndex != -1) {
          nameWithoutExtension = material.title.substring(0, lastDotIndex);
          extension = material.title.substring(lastDotIndex);
        } else {
          nameWithoutExtension = material.title;
          extension = '';
        }

        // 最多检查100个可能的文件名
        for (int counter = 1; counter <= 100; counter++) {
          final String newFilename =
              '$nameWithoutExtension($counter)$extension';
          final String newFilePath = '$downloadPath/$newFilename';
          final File newFile = File(newFilePath);

          if (await newFile.exists()) {
            return true; // 找到了一个已下载的文件
          }
        }

        return false; // 没有找到任何相关文件
      }

      return true; // 原始文件名存在
    } catch (e) {
      debugPrint('检查文件下载状态出错: $e');
      return false;
    }
  }

  // 构建资料项卡片
  Widget _buildMaterialItem(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final fileSizeText =
        material.fileSize != null
            ? _formatFileSize(material.fileSize!)
            : '未知大小';
    final typeIcon = _getMaterialTypeIcon(material.type);
    final typeColor = _getMaterialTypeColor(material.type);

    return FutureBuilder<bool>(
      future: _isFileDownloaded(material),
      builder: (context, snapshot) {
        final bool isDownloaded = snapshot.data ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              if (isDownloaded) {
                // 如果已下载，打开文件所在文件夹
                _openDownloadedMaterial(context, material, ref);
              } else {
                // 如果未下载，则下载文件
                _downloadMaterial(context, material, ref);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 资料类型图标
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(typeIcon, color: typeColor, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 资料信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (material.description != null &&
                                material.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  material.description!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  if (material.uploaderName != null)
                                    Text(
                                      '${material.uploaderName} · ',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (material.uploadTime != null)
                                    Text(
                                      '${dateFormat.format(material.uploadTime!)} · ',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  Text(
                                    fileSizeText,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isDownloaded)
                          // 如果已下载，显示"已下载"状态
                          OutlinedButton.icon(
                            onPressed:
                                () => _openDownloadedMaterial(
                                  context,
                                  material,
                                  ref,
                                ),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('已下载'),
                          )
                        else
                          // 如果未下载，显示下载按钮
                          OutlinedButton.icon(
                            onPressed:
                                () => _downloadMaterial(context, material, ref),
                            icon: const Icon(Icons.download),
                            label: const Text('下载'),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => _confirmDeleteMaterial(
                                context,
                                ref,
                                material.id,
                              ),
                          tooltip: '删除资料',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 显示添加资料对话框
  void _showAddMaterialDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    models.MaterialType selectedType = models.MaterialType.document;
    PlatformFile? selectedFile;
    String? fileName;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('添加资料'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: '标题',
                            hintText: '例如：项目进度报告',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: '描述 (可选)',
                            hintText: '例如：详细的项目进度统计报告',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<models.MaterialType>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: '资料类型'),
                          items: [
                            DropdownMenuItem(
                              value: models.MaterialType.document,
                              child: Row(
                                children: [
                                  Icon(
                                    _getMaterialTypeIcon(
                                      models.MaterialType.document,
                                    ),
                                    color: _getMaterialTypeColor(
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
                                    _getMaterialTypeIcon(
                                      models.MaterialType.image,
                                    ),
                                    color: _getMaterialTypeColor(
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
                                    _getMaterialTypeIcon(
                                      models.MaterialType.video,
                                    ),
                                    color: _getMaterialTypeColor(
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
                                    _getMaterialTypeIcon(
                                      models.MaterialType.presentation,
                                    ),
                                    color: _getMaterialTypeColor(
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
                                    _getMaterialTypeIcon(
                                      models.MaterialType.other,
                                    ),
                                    color: _getMaterialTypeColor(
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
                                onPressed: () async {
                                  // 打开文件选择器
                                  FilePickerResult? result = await FilePicker
                                      .platform
                                      .pickFiles(
                                        type: FileType.any,
                                        allowMultiple: false,
                                      );

                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setState(() {
                                      selectedFile = result.files.first;
                                      fileName = selectedFile!.name;

                                      // 如果标题为空，使用文件名作为标题
                                      if (titleController.text.isEmpty) {
                                        titleController.text = fileName!;
                                      }

                                      // 根据文件扩展名自动选择类型
                                      final extension =
                                          fileName!
                                              .split('.')
                                              .last
                                              .toLowerCase();
                                      if ([
                                        'jpg',
                                        'jpeg',
                                        'png',
                                        'gif',
                                        'webp',
                                      ].contains(extension)) {
                                        selectedType =
                                            models.MaterialType.image;
                                      } else if ([
                                        'mp4',
                                        'mov',
                                        'avi',
                                        'mkv',
                                        'webm',
                                      ].contains(extension)) {
                                        selectedType =
                                            models.MaterialType.video;
                                      } else if ([
                                        'ppt',
                                        'pptx',
                                        'key',
                                      ].contains(extension)) {
                                        selectedType =
                                            models.MaterialType.presentation;
                                      } else if ([
                                        'doc',
                                        'docx',
                                        'pdf',
                                        'txt',
                                        'xls',
                                        'xlsx',
                                      ].contains(extension)) {
                                        selectedType =
                                            models.MaterialType.document;
                                      } else {
                                        selectedType =
                                            models.MaterialType.other;
                                      }
                                    });
                                  }
                                },
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
                      onPressed:
                          selectedFile == null
                              ? null // 如果没有选择文件，禁用按钮
                              : () async {
                                if (titleController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('请输入资料标题')),
                                  );
                                  return;
                                }

                                // 显示加载指示器
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                );

                                try {
                                  // 获取当前用户信息
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final userJson = prefs.getString(
                                    AppConstants.userKey,
                                  );
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
                                    Uri.parse(
                                      '${AppConstants.apiBaseUrl}/meeting/file/upload/$meetingId',
                                    ),
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
                                  request.headers.addAll(
                                    HttpUtils.createHeaders(),
                                  );

                                  // 添加其他字段
                                  request.fields['meetingId'] = meetingId;
                                  request.fields['uploaderId'] = uploaderId;
                                  request.fields['uploaderName'] = uploaderName;

                                  // 发送请求
                                  final streamedResponse = await request.send();
                                  final response = await http
                                      .Response.fromStream(streamedResponse);

                                  // 确保widget仍然挂载在树上
                                  if (!context.mounted) return;

                                  // 处理响应
                                  if (response.statusCode == 200) {
                                    final responseData =
                                        HttpUtils.decodeResponse(response);

                                    if (responseData['code'] == 200) {
                                      // 上传成功后刷新列表
                                      ref.invalidate(
                                        meetingMaterialsNotifierProvider(
                                          meetingId,
                                        ),
                                      );

                                      // 关闭加载指示器
                                      Navigator.of(context).pop();

                                      // 关闭对话框
                                      Navigator.of(context).pop();

                                      // 显示成功消息
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('资料上传成功')),
                                      );
                                    } else {
                                      // 关闭加载指示器
                                      Navigator.of(context).pop();

                                      final message =
                                          responseData['message'] ?? '资料上传失败';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    }
                                  } else {
                                    // 关闭加载指示器
                                    Navigator.of(context).pop();

                                    // 显示错误消息
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '上传失败: ${response.statusCode} - ${response.body}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // 确保widget仍然挂载在树上
                                  if (!context.mounted) return;

                                  // 关闭加载指示器
                                  Navigator.of(context).pop();

                                  // 显示错误消息
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('上传失败: $e')),
                                  );
                                }
                              },
                      child: const Text('上传'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 确认删除资料
  void _confirmDeleteMaterial(
    BuildContext context,
    WidgetRef ref,
    String materialId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个资料吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  // 显示加载指示器
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // 调用删除API
                    final response = await http.delete(
                      Uri.parse(
                        '${AppConstants.apiBaseUrl}/meeting/file/delete/$materialId',
                      ),
                      headers: HttpUtils.createHeaders(),
                    );

                    // 确保widget仍然挂载在树上
                    if (!context.mounted) return;

                    // 关闭加载指示器
                    Navigator.of(context).pop();
                    // 关闭确认对话框
                    Navigator.of(context).pop();

                    // 处理响应
                    if (response.statusCode == 200) {
                      final responseData = HttpUtils.decodeResponse(response);

                      if (responseData['code'] == 200) {
                        // 删除成功，刷新资料列表
                        ref.invalidate(
                          meetingMaterialsNotifierProvider(meetingId),
                        );

                        // 显示成功消息
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('资料删除成功')));
                      } else {
                        // 显示错误消息
                        final message = responseData['message'] ?? '资料删除失败';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    } else {
                      // 显示错误消息
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('删除失败: ${response.statusCode}')),
                      );
                    }
                  } catch (e) {
                    // 确保widget仍然挂载在树上
                    if (!context.mounted) return;

                    // 关闭加载指示器
                    Navigator.of(context).pop();
                    // 关闭确认对话框
                    Navigator.of(context).pop();

                    // 显示错误消息
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  // 处理已下载文件的打开
  void _openDownloadedMaterial(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
  ) async {
    try {
      // 获取下载路径
      final String downloadPath = await _getDownloadPath();
      final String filePath = '$downloadPath/${material.title}';
      final file = File(filePath);

      if (await file.exists()) {
        // 文件存在，打开文件所在文件夹
        await _openFileLocation(filePath);
        return;
      }

      // 原文件不存在，检查是否有同名带编号的文件
      final int lastDotIndex = material.title.lastIndexOf('.');
      String nameWithoutExtension;
      String extension;

      if (lastDotIndex != -1) {
        nameWithoutExtension = material.title.substring(0, lastDotIndex);
        extension = material.title.substring(lastDotIndex);
      } else {
        nameWithoutExtension = material.title;
        extension = '';
      }

      // 尝试查找文件
      for (int counter = 1; counter <= 100; counter++) {
        final String newFilename = '$nameWithoutExtension($counter)$extension';
        final String newFilePath = '$downloadPath/$newFilename';
        final File newFile = File(newFilePath);

        if (await newFile.exists()) {
          // 找到文件，打开文件所在文件夹
          await _openFileLocation(newFilePath);
          return;
        }
      }

      // 没有找到文件，可能已被移动或删除
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文件不存在或已被移动，请重新下载')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开文件位置失败: $e')));
    }
  }

  // 下载资料
  void _downloadMaterial(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
  ) async {
    try {
      // 在Web平台上，直接打开URL即可下载
      if (kIsWeb) {
        // 构造正确的下载URL
        final String downloadUrl =
            '${AppConstants.apiBaseUrl}/meeting/file/download/$meetingId/${material.id}';
        await launchUrl(Uri.parse(downloadUrl));
        return;
      }

      // 请求存储权限
      if (!await _requestStoragePermission(context)) {
        return; // 如果权限被拒绝，中止下载
      }

      if (!context.mounted) return;

      // 显示加载指示器
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text('正在下载: ${material.title}'),
            ],
          ),
          duration: const Duration(seconds: 30), // 设置较长的显示时间
        ),
      );

      // 获取系统下载目录
      final String downloadPath = await _getDownloadPath();

      // 处理文件名重复问题
      final String originalFilename = material.title;
      String filePath = '$downloadPath/$originalFilename';

      // 检查文件是否已存在，如果存在则添加编号
      final file = File(filePath);
      if (await file.exists()) {
        // 分离文件名和扩展名
        final int lastDotIndex = originalFilename.lastIndexOf('.');
        String nameWithoutExtension;
        String extension;

        if (lastDotIndex != -1) {
          nameWithoutExtension = originalFilename.substring(0, lastDotIndex);
          extension = originalFilename.substring(lastDotIndex);
        } else {
          nameWithoutExtension = originalFilename;
          extension = '';
        }

        // 尝试查找一个可用的文件名，最多尝试100次
        int counter = 1;
        String newFilename;
        File newFile;

        do {
          newFilename = '$nameWithoutExtension($counter)$extension';
          filePath = '$downloadPath/$newFilename';
          newFile = File(filePath);
          counter++;
        } while (await newFile.exists() && counter <= 100);
      }

      // 确保目录存在
      final directory = File(filePath).parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 构造正确的下载URL
      final String downloadUrl =
          '${AppConstants.apiBaseUrl}/meeting/file/download/$meetingId/${material.id}';

      // 下载文件
      final response = await http.get(Uri.parse(downloadUrl));

      // 写入文件
      await File(filePath).writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;

      // 获取下载后的文件名
      final downloadedFilename = filePath.split('/').last;

      // 显示成功消息，包含文件路径，并提供打开选项
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('已下载: $downloadedFilename'),
              const SizedBox(height: 4),
              Text(
                '路径: $filePath',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          action: SnackBarAction(
            label: '打开',
            onPressed: () {
              _openFileLocation(filePath);
            },
          ),
        ),
      );

      // 刷新当前材料列表状态
      ref.invalidate(meetingMaterialsNotifierProvider(meetingId));
    } catch (e) {
      if (!context.mounted) return;

      // 显示错误消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // 非移动平台不需要请求权限
      return true;
    }

    if (Platform.isAndroid) {
      // Android 13+需要照片和视频权限
      try {
        // 先检查是否永久拒绝了权限
        if (await Permission.photos.isPermanentlyDenied ||
            await Permission.videos.isPermanentlyDenied) {
          // 如果任一权限被永久拒绝，引导用户去设置页面开启权限
          if (!context.mounted) return false;
          return _showSettingsDialog(context, '照片和视频');
        }

        // 尝试请求照片权限
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          // 用户拒绝了权限，但未永久拒绝，不显示对话框，直接返回失败
          return false;
        }

        // 尝试请求视频权限
        final videosStatus = await Permission.videos.request();
        if (!videosStatus.isGranted) {
          // 用户拒绝了权限，但未永久拒绝，不显示对话框，直接返回失败
          return false;
        }

        // 所有权限都已获取
        return true;
      } catch (e) {
        debugPrint('请求权限出错: $e');
        // 出错时尝试请求存储权限（兜底方案）
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS请求照片权限
      if (await Permission.photos.isPermanentlyDenied) {
        // 永久拒绝时引导用户去设置
        if (!context.mounted) return false;
        return _showSettingsDialog(context, '照片访问');
      }

      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true;
  }

  // 显示设置对话框
  Future<bool> _showSettingsDialog(
    BuildContext context,
    String permissionName,
  ) async {
    if (!context.mounted) return false;

    final bool? goToSettings = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('需要权限'),
            content: Text('下载文件需要$permissionName权限，请在设置中开启'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('前往设置'),
              ),
            ],
          ),
    );

    if (!context.mounted) return false;

    if (goToSettings == true) {
      await openAppSettings();
    }

    return false;
  }

  // 获取系统下载目录路径
  Future<String> _getDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        // Android: 使用公共下载目录
        // 直接使用公共路径，需要已经有存储权限
        const downloadPath = '/storage/emulated/0/Download';
        final downloadDir = Directory(downloadPath);

        // 确保目录存在
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadPath;
      } else if (Platform.isWindows) {
        // Windows: 使用用户下载目录
        return '${Platform.environment['USERPROFILE']}\\Downloads';
      } else if (Platform.isMacOS || Platform.isLinux) {
        // macOS/Linux: 使用用户下载目录
        return '${Platform.environment['HOME']}/Downloads';
      }

      // 其他平台或回退策略: 使用应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDirectory = Directory('${directory.path}/Downloads');
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }
      return downloadsDirectory.path;
    } catch (e) {
      // 如果发生任何错误，回退到临时目录
      final directory = await getTemporaryDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir.path;
    }
  }

  // 打开文件所在位置
  Future<void> _openFileLocation(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('文件不存在: $filePath');
        return;
      }

      if (Platform.isAndroid) {
        // 在Android上直接使用系统文件浏览器打开文件夹
        final directory = file.parent.path;

        // 尝试构建一个文件夹的content URI
        final contentUri = Uri.parse(
          'content://com.android.externalstorage.documents/document/primary:${directory.replaceFirst('/storage/emulated/0/', '')}',
        );

        // 使用ACTION_VIEW打开文件夹
        if (await canLaunchUrl(contentUri)) {
          await launchUrl(contentUri, mode: LaunchMode.externalApplication);
        } else {
          // 如果无法打开content URI，尝试直接打开文件URI
          final fileUri = Uri.parse('file://$directory');
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          } else {
            debugPrint('无法打开文件夹: $directory');
          }
        }
      } else if (Platform.isWindows) {
        // Windows: 使用explorer打开文件所在文件夹并选中文件
        await Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        // macOS: 使用open -R命令打开文件所在文件夹并选中文件
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        // Linux: 尝试使用xdg-open打开文件所在文件夹
        final directory = file.parent.path;
        await Process.run('xdg-open', [directory]);
      } else {
        // 其他平台: 尝试直接打开文件
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('打开文件位置失败: $e');
    }
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // 获取资料类型图标
  IconData _getMaterialTypeIcon(models.MaterialType type) {
    switch (type) {
      case models.MaterialType.document:
        return Icons.insert_drive_file;
      case models.MaterialType.image:
        return Icons.image;
      case models.MaterialType.video:
        return Icons.videocam;
      case models.MaterialType.presentation:
        return Icons.slideshow;
      case models.MaterialType.other:
        return Icons.attachment;
    }
  }

  // 获取资料类型颜色
  Color _getMaterialTypeColor(models.MaterialType type) {
    switch (type) {
      case models.MaterialType.document:
        return Colors.blue;
      case models.MaterialType.image:
        return Colors.green;
      case models.MaterialType.video:
        return Colors.red;
      case models.MaterialType.presentation:
        return Colors.orange;
      case models.MaterialType.other:
        return Colors.grey;
    }
  }
}
