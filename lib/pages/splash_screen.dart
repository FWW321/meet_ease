import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_checker.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  // 页面退出动画控制器
  AnimationController? _exitController;
  Animation<double>? _exitAnimation;

  // 会议座位布局动画
  final List<SeatItem> _seats = [];
  final int _seatCount = 12;

  // 粒子效果
  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();

    // 主动画控制器
    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // 脉冲动画控制器 - 用于圆圈呼吸效果
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // 粒子动画控制器
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 初始化座位
    _initSeats();

    // 初始化粒子
    _initParticles();

    // 启动动画
    _mainController.forward();
    _particleController.repeat();

    // 为过渡到主页添加动画监听
    _mainController.addStatusListener(_animationStatusListener);
  }

  // 动画状态监听器
  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 主动画完成后开始准备退出
      _prepareExit();
    }
  }

  // 准备退出开屏界面
  void _prepareExit() {
    // 在主动画完成后添加一些额外的缓冲时间再退出
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // 创建淡出动画控制器
      _exitController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      // 创建淡出动画
      _exitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitController!, curve: Curves.easeOut),
      );

      // 开始淡出整个开屏页面
      setState(() {}); // 确保重建UI以应用退出动画

      _exitController!.forward().then((_) {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const AuthChecker(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              // 组合多种转场效果
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                ),
              );

              final scaleAnimation = Tween<double>(
                begin: 0.98,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
                ),
              );

              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.03),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
                ),
              );

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      });
    });
  }

  // 初始化会议座位
  void _initSeats() {
    for (int i = 0; i < _seatCount; i++) {
      final double angle = (i / _seatCount) * 2 * math.pi;
      final double delay = i / _seatCount * 0.5;

      _seats.add(
        SeatItem(angle: angle, delay: delay, controller: _mainController),
      );
    }
  }

  // 初始化粒子
  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          initialPosition: Offset(
            random.nextDouble() * 300 - 150,
            random.nextDouble() * 300 - 150,
          ),
          speed: random.nextDouble() * 2 + 1,
          angle: random.nextDouble() * 2 * math.pi,
          size: random.nextDouble() * 10 + 5,
          controller: _particleController,
        ),
      );
    }
  }

  @override
  void dispose() {
    // 移除监听器
    _mainController.removeStatusListener(_animationStatusListener);
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _exitController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedBuilder(
        animation: _exitController ?? _mainController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitAnimation?.value ?? 1.0,
            child: Stack(
              children: [
                // 背景网格
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(
                      lineColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                ),

                // 中心圆圈脉冲
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: size.width * 0.5,
                          height: size.width * 0.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 会议座位/参与者
                Center(
                  child: SizedBox(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    child: Stack(
                      children:
                          _seats.map((seat) {
                            return AnimatedBuilder(
                              animation: _mainController,
                              builder: (context, child) {
                                // 延迟显示
                                final delayedValue = math.max(
                                  0.0,
                                  math.min(
                                    1.0,
                                    (_mainController.value - seat.delay) /
                                        (1 - seat.delay),
                                  ),
                                );

                                if (delayedValue <= 0) {
                                  return const SizedBox();
                                }

                                // 座位位置计算
                                final radius = size.width * 0.25;
                                final x = math.cos(seat.angle) * radius;
                                final y = math.sin(seat.angle) * radius;

                                return Positioned(
                                  left: size.width * 0.3 + x - 15,
                                  top: size.width * 0.3 + y - 15,
                                  child: Opacity(
                                    opacity: delayedValue,
                                    child: Transform.scale(
                                      scale: delayedValue,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.7),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ),
                  ),
                ),

                // 中心会议图标
                Center(
                  child: AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: size.width * 0.25,
                              height: size.width * 0.25,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 粒子效果
                Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.width,
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ParticlePainter(
                            particles: _particles,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 底部内容 - 应用名称和描述
                Positioned(
                  bottom: size.height * 0.15,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // 应用名称
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'MeetEase',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      // 应用描述
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          '高效会议管理系统',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      // 加载指示器
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: AnimatedBuilder(
                          animation: _mainController,
                          builder: (context, child) {
                            // 根据主动画完成状态决定进度条的可见性
                            double opacity = 1.0;

                            // 当主动画接近完成时，加载指示器开始淡出
                            if (_mainController.value > 0.9) {
                              opacity =
                                  10.0 *
                                  (1.0 - _mainController.value); // 0.9到1.0之间淡出
                            }

                            return Opacity(
                              opacity: opacity,
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _mainController.value,
                                    minHeight: 6,
                                    backgroundColor: theme.colorScheme.surface,
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  // 显示当前加载进度百分比
                                  if (_mainController.value < 0.99) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_mainController.value * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: opacity),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 会议图标飞入动画
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // 日历图标
                        _buildFlyingIcon(
                          icon: Icons.calendar_month,
                          startX: -50,
                          startY: size.height * 0.3,
                          endX: size.width / 2 - 20,
                          endY: size.height / 2,
                          delay: 0.0,
                          size: 30,
                        ),

                        // 文档图标
                        _buildFlyingIcon(
                          icon: Icons.description,
                          startX: size.width + 50,
                          startY: size.height * 0.4,
                          endX: size.width / 2 + 20,
                          endY: size.height / 2 + 10,
                          delay: 0.1,
                          size: 28,
                        ),

                        // 通知图标
                        _buildFlyingIcon(
                          icon: Icons.notifications,
                          startX: size.width * 0.2,
                          startY: -50,
                          endX: size.width / 2 - 30,
                          endY: size.height / 2 - 20,
                          delay: 0.2,
                          size: 26,
                        ),

                        // 任务图标
                        _buildFlyingIcon(
                          icon: Icons.task_alt,
                          startX: size.width * 0.8,
                          startY: -50,
                          endX: size.width / 2 + 25,
                          endY: size.height / 2 - 25,
                          delay: 0.3,
                          size: 24,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 飞入图标构建助手
  Widget _buildFlyingIcon({
    required IconData icon,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double delay,
    required double size,
  }) {
    final animationValue = _mainController.value;

    // 应用延迟
    final delayedValue = math.max(
      0.0,
      math.min(1.0, (animationValue - delay) / (1 - delay)),
    );

    // 如果尚未开始动画，则不显示
    if (delayedValue <= 0) {
      return const SizedBox();
    }

    // 计算当前位置
    final currentX = startX + (endX - startX) * delayedValue;
    final currentY = startY + (endY - startY) * delayedValue;

    // 透明度曲线 - 从0到1，然后在接近结束时再次回到0
    double opacity = 1.0;
    if (delayedValue > 0.8) {
      opacity = 1.0 - (delayedValue - 0.8) * 5; // 从0.8到1.0之间逐渐消失
    } else if (delayedValue < 0.2) {
      opacity = delayedValue * 5; // 从0到0.2之间逐渐出现
    }

    return Positioned(
      left: currentX,
      top: currentY,
      child: Opacity(
        opacity: opacity,
        child: Icon(
          icon,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// 座位数据类
class SeatItem {
  final double angle;
  final double delay;
  final AnimationController controller;

  SeatItem({
    required this.angle,
    required this.delay,
    required this.controller,
  });
}

// 粒子数据类
class Particle {
  final Offset initialPosition;
  final double speed;
  final double angle;
  final double size;
  final AnimationController controller;

  Particle({
    required this.initialPosition,
    required this.speed,
    required this.angle,
    required this.size,
    required this.controller,
  });

  Offset get position {
    final time = controller.value * 2 * math.pi;
    final dx = initialPosition.dx + math.cos(angle + time) * speed * 10;
    final dy = initialPosition.dy + math.sin(angle + time) * speed * 10;
    return Offset(dx, dy);
  }
}

// 粒子效果绘制器
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final paint =
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..style = PaintingStyle.fill;

      final position = center + particle.position;
      canvas.drawCircle(position, particle.size, paint);

      // 绘制粒子尾巴/轨迹
      final tailPaint =
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

      final path = Path();
      path.moveTo(position.dx, position.dy);

      final tailLength = particle.size * 2;
      final tailAngle = particle.angle + math.pi; // 尾巴方向与运动方向相反

      path.lineTo(
        position.dx + math.cos(tailAngle) * tailLength,
        position.dy + math.sin(tailAngle) * tailLength,
      );

      canvas.drawPath(path, tailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 网格背景绘制
class GridPainter extends CustomPainter {
  final Color lineColor;

  GridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.0;

    // 绘制水平线
    double gridSize = 40;
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制会议室布局
    final roomPaint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.7)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    // 会议室外围边框
    final roomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.6,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(roomRect, roomPaint);

    // 会议桌
    final tablePaint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.5)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final tableRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.5,
        size.height * 0.3,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(tableRect, tablePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
