import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show File, Platform, Process;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../../models/meeting_material.dart' as models;
import '../../constants/app_constants.dart';
import '../../providers/meeting_process_providers.dart';
import '../../utils/http_utils.dart';
import 'material_utils.dart';

/// 会议资料操作类
class MaterialActions {
  /// 确认删除资料
  static void confirmDeleteMaterial(
    BuildContext context,
    WidgetRef ref,
    String materialId,
    String meetingId,
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

  /// 处理已下载文件的打开
  static Future<void> openDownloadedMaterial(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
  ) async {
    try {
      // 获取下载路径
      final String downloadPath = await MaterialUtils.getDownloadPath();
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

  /// 下载资料
  static Future<void> downloadMaterial(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
    String meetingId,
  ) async {
    try {
      // 在Web平台上，直接打开URL即可下载
      if (kIsWeb) {
        // 构造正确的下载URL
        final String downloadUrl =
            '${AppConstants.apiBaseUrl}/meeting/file/download/${material.id}';
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
      final String downloadPath = await MaterialUtils.getDownloadPath();

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
          '${AppConstants.apiBaseUrl}/meeting/file/download/${material.id}';

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

  /// 请求存储权限
  static Future<bool> _requestStoragePermission(BuildContext context) async {
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

  /// 显示设置对话框
  static Future<bool> _showSettingsDialog(
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

  /// 打开文件所在位置
  static Future<void> _openFileLocation(String filePath) async {
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
}
