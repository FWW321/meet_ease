import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP工具类，用于处理网络请求中的编码问题
class HttpUtils {
  /// 解码HTTP响应，确保中文正确显示
  static Map<String, dynamic> decodeResponse(http.Response response) {
    // 使用utf8解码响应体，避免中文乱码
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// 解码HTTP响应为列表，确保中文正确显示
  static List<dynamic> decodeResponseList(http.Response response) {
    // 使用utf8解码响应体，避免中文乱码
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  /// 从响应中提取错误信息
  static String extractErrorMessage(
    http.Response response, {
    String defaultMessage = '请求失败',
  }) {
    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      return errorData['message']?.toString() ??
          '$defaultMessage: ${response.statusCode}';
    } catch (e) {
      return '$defaultMessage: ${response.statusCode}';
    }
  }

  /// 创建通用的请求头
  static Map<String, String> createHeaders({
    Map<String, String>? additionalHeaders,
  }) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }
}
