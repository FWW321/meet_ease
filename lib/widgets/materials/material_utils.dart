import 'package:flutter/material.dart';
import 'dart:io' show File, Platform, Directory;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/meeting_material.dart' as models;

/// 会议资料工具类
class MaterialUtils {
  /// 获取资料类型图标
  static IconData getMaterialTypeIcon(models.MaterialType type) {
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

  /// 获取资料类型颜色
  static Color getMaterialTypeColor(models.MaterialType type) {
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

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
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

  /// 检查文件是否已下载
  static Future<bool> isFileDownloaded(models.MaterialItem material) async {
    try {
      // 在Web平台上总是返回false
      if (kIsWeb) {
        return false;
      }

      // 获取下载路径
      final String downloadPath = await getDownloadPath();

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

  /// 获取系统下载目录路径
  static Future<String> getDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        // Android: 使用公共下载目录
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
}
