import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 时间工具类，用于处理各种时间相关的操作
class TimeUtils {
  static const String shanghaiTimeZone = 'Asia/Shanghai';
  static bool _initialized = false;

  /// 初始化时区数据
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      _initialized = true;
    } catch (e) {
      debugPrint('初始化时区数据失败: $e');
    }
  }

  /// 检查时区是否为上海时区
  static bool isShanghaiTimeZone(String? timeZoneName) {
    return timeZoneName == shanghaiTimeZone;
  }

  /// 获取上海时区的当前时间
  static DateTime nowInShanghaiTimeZone() {
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  /// 将UTC时间转换为上海时区时间
  static DateTime utcToShanghaiTimeZone(DateTime utcTime) {
    return utcTime.add(const Duration(hours: 8));
  }

  /// 将上海时区时间转换为UTC时间
  static DateTime shanghaiToUtcTimeZone(DateTime shanghaiTime) {
    return shanghaiTime.subtract(const Duration(hours: 8));
  }

  /// 将 DateTime 转换为上海时区时间
  /// 如果输入的时间已经是上海时区，则直接返回
  /// 如果输入的时间没有明确时区信息，则假定其为本地时间，转换为上海时区
  static DateTime toShanghaiTimeZone(DateTime dateTime) {
    _ensureInitialized();

    // 如果日期已经是上海时区的，直接返回
    if (dateTime is tz.TZDateTime &&
        isShanghaiTimeZone(dateTime.location.name)) {
      return dateTime;
    }

    final shangHai = tz.getLocation(shanghaiTimeZone);

    // 如果是普通的DateTime（没有时区信息），则将其视为本地时间，然后转为上海时区
    if (dateTime is! tz.TZDateTime) {
      // 使用from()函数将普通DateTime转为上海时区
      return tz.TZDateTime.from(dateTime, shangHai);
    }

    // 如果是其他时区的TZDateTime，转换到上海时区
    return tz.TZDateTime.from(dateTime, shangHai);
  }

  /// 将时间戳（毫秒）转换为上海时区的DateTime
  static DateTime fromMillisecondsSinceEpoch(int milliseconds) {
    _ensureInitialized();
    final shangHai = tz.getLocation(shanghaiTimeZone);
    return tz.TZDateTime.fromMillisecondsSinceEpoch(shangHai, milliseconds);
  }

  /// 将ISO8601格式的时间字符串转换为上海时区的DateTime
  static DateTime fromIso8601String(String dateString) {
    _ensureInitialized();
    final dateTime = DateTime.parse(dateString);
    return toShanghaiTimeZone(dateTime);
  }

  /// 格式化日期时间
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'yyyy-MM-dd HH:mm:ss',
  }) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  /// 格式化日期
  static String formatDate(DateTime dateTime, {String format = 'yyyy-MM-dd'}) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  /// 格式化时间
  static String formatTime(DateTime dateTime, {String format = 'HH:mm:ss'}) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  /// 获取相对时间表示（例如：3分钟前，2小时前等）
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30}个月前';
    } else {
      return '${difference.inDays ~/ 365}年前';
    }
  }

  /// 从字符串解析日期时间
  static DateTime parseDateTime(
    String dateTimeString, {
    String format = 'yyyy-MM-dd HH:mm:ss',
  }) {
    final formatter = DateFormat(format);
    return formatter.parse(dateTimeString);
  }

  /// 确保时区数据已初始化
  static void _ensureInitialized() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  /// 比较两个日期是否在同一天（上海时区）
  static bool isSameDay(DateTime a, DateTime b) {
    final aSh = toShanghaiTimeZone(a);
    final bSh = toShanghaiTimeZone(b);

    return aSh.year == bSh.year && aSh.month == bSh.month && aSh.day == bSh.day;
  }

  /// 获取指定日期在上海时区的日期部分（时分秒为0）
  static DateTime getDateOnly(DateTime dateTime) {
    final shanghaiTime = toShanghaiTimeZone(dateTime);
    final shangHai = tz.getLocation(shanghaiTimeZone);
    return tz.TZDateTime(
      shangHai,
      shanghaiTime.year,
      shanghaiTime.month,
      shanghaiTime.day,
    );
  }

  /// 检查日期是否在今天（上海时区）
  static bool isToday(DateTime dateTime) {
    return isSameDay(dateTime, nowInShanghaiTimeZone());
  }

  /// 检查日期是否在昨天（上海时区）
  static bool isYesterday(DateTime dateTime) {
    final yesterday = nowInShanghaiTimeZone().subtract(const Duration(days: 1));
    return isSameDay(dateTime, yesterday);
  }
}
