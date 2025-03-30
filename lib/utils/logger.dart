import 'package:logger/logger.dart';

/// 全局日志工具
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
  level: Level.debug,
);

/// 扩展Logger类，添加自定义方法
extension LoggerExtension on Logger {
  /// 打印网络请求日志
  void network(String message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.info, '🌐 $message', error: error, stackTrace: stackTrace);
  }

  /// 打印业务逻辑日志
  void business(String message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.info, '💼 $message', error: error, stackTrace: stackTrace);
  }

  /// 打印用户行为日志
  void user(String message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.info, '👤 $message', error: error, stackTrace: stackTrace);
  }
}
