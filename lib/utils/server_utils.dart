import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 服务器工具类
class ServerUtils {
  /// 验证服务器地址格式
  static bool isValidServerAddress(String address) {
    // 检查是否包含端口号
    final parts = address.split(':');
    if (parts.length != 2) return false;

    // 检查端口是否为数字
    final port = int.tryParse(parts[1]);
    if (port == null || port <= 0 || port > 65535) return false;

    return true;
  }

  /// 测试服务器连接
  static Future<bool> testServerConnection(String serverAddress) async {
    try {
      // 验证地址格式
      final serverParts = serverAddress.split(':');
      if (serverParts.length != 2) {
        throw Exception('服务器地址格式不正确');
      }

      final host = serverParts[0];
      final port = int.tryParse(serverParts[1]);

      if (port == null) {
        throw Exception('端口格式不正确');
      }

      // 创建一个Socket连接来测试服务器是否可达
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      // 成功建立连接
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 处理服务器地址编辑
  static Future<bool> handleServerAddressEdit(
    BuildContext context,
    String newAddress,
  ) async {
    if (newAddress.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('服务器地址不能为空')));
      return false;
    }

    // 验证服务器地址格式
    if (!isValidServerAddress(newAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址格式不正确，应为 IP:端口 或 域名:端口')),
      );
      return false;
    }

    // 更新服务器地址
    await AppConstants.updateApiDomain(newAddress);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('服务器地址已更新')));
    return true;
  }

  /// 显示服务器连接测试结果
  static void showConnectionTestResult(
    BuildContext context,
    bool isSuccess, [
    String? errorMessage,
  ]) {
    if (isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('服务器连接成功！')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法连接到服务器: ${errorMessage ?? "连接失败"}')),
      );
    }
  }
}
