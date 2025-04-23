import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 时间工具类，用于处理时区转换
/// 主要功能是将各种时区的时间统一转换为上海时区(Asia/Shanghai)
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

  /// 获取当前上海时区时间
  static DateTime nowInShanghaiTimeZone() {
    _ensureInitialized();
    final shangHai = tz.getLocation(shanghaiTimeZone);
    return tz.TZDateTime.now(shangHai);
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

  /// 将UTC时间转换为上海时区时间
  /// 如果输入的不是UTC时间，会先将其转换为UTC时间，再转为上海时区
  static DateTime utcToShanghaiTimeZone(DateTime dateTime) {
    _ensureInitialized();

    // 确保输入时间是UTC时间
    final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();

    // 转换为上海时区
    final shangHai = tz.getLocation(shanghaiTimeZone);
    return tz.TZDateTime.from(utcDateTime, shangHai);
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

  /// 格式化日期时间为易读的字符串
  /// 使用intl包的DateFormat进行格式化
  ///
  /// 常用格式：
  /// - yyyy-MM-dd HH:mm:ss 标准日期时间 2023-01-01 13:01:01
  /// - yyyy-MM-dd 仅日期 2023-01-01
  /// - HH:mm:ss 仅时间 13:01:01
  /// - yyyy年MM月dd日 HH时mm分 中文格式 2023年01月01日 13时01分
  /// 更多格式参考 intl 包文档
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'yyyy-MM-dd HH:mm:ss',
  }) {
    final shanghaiTime = toShanghaiTimeZone(dateTime);
    final DateFormat formatter = DateFormat(format);
    return formatter.format(shanghaiTime);
  }

  /// 格式化为友好的时间表示
  /// 如：刚刚、5分钟前、1小时前、昨天、前天、3天前等
  static String formatToFriendlyTime(DateTime dateTime) {
    final shanghaiTime = toShanghaiTimeZone(dateTime);
    final now = nowInShanghaiTimeZone();
    final difference = now.difference(shanghaiTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 2) {
      return '昨天 ${formatDateTime(shanghaiTime, format: 'HH:mm')}';
    } else if (difference.inDays < 3) {
      return '前天 ${formatDateTime(shanghaiTime, format: 'HH:mm')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (shanghaiTime.year == now.year) {
      return formatDateTime(shanghaiTime, format: 'MM月dd日 HH:mm');
    } else {
      return formatDateTime(shanghaiTime, format: 'yyyy年MM月dd日 HH:mm');
    }
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
