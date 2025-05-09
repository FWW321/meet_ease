import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/auth_service.dart';
import '../pages/home_page.dart';
import '../pages/register_page.dart';
import '../constants/app_constants.dart';
import '../utils/server_utils.dart';
import '../providers/user_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverAddressController =
      TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _isEditingServer = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _serverAddressController.text = AppConstants.apiDomain;

    // 添加动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverAddressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用Riverpod的authStateProvider管理登录状态
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // 保存登录状态
      await AuthService.saveLoginStatus(true);

      if (!mounted) return;

      // 显示登录成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('登录成功'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 延迟一下再跳转，让用户看到成功提示
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
    } catch (e) {
      if (!mounted) return;
      String errorMessage = '登录失败';

      // 提取异常中的具体信息
      final String errorString = e.toString();
      if (errorString.contains('Exception:')) {
        errorMessage = errorString.split('Exception:')[1].trim();
      } else {
        errorMessage = '登录失败: $errorString';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 测试服务器连接
  Future<void> _testServerConnection() async {
    if (_isEditingServer) {
      // 如果正在编辑服务器地址，则保存地址
      final newAddress = _serverAddressController.text.trim();
      final success = await ServerUtils.handleServerAddressEdit(
        context,
        newAddress,
      );

      if (success) {
        setState(() {
          _isEditingServer = false;
        });
      }
    } else {
      setState(() {
        _isTestingConnection = true;
      });

      try {
        final isConnected = await ServerUtils.testServerConnection(
          AppConstants.apiDomain,
        );

        if (!mounted) return;
        ServerUtils.showConnectionTestResult(
          context,
          isConnected,
          isConnected ? null : '无法建立连接',
        );
      } catch (e) {
        if (!mounted) return;
        ServerUtils.showConnectionTestResult(context, false, e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isTestingConnection = false;
          });
        }
      }
    }
  }

  // 切换服务器地址编辑模式
  void _toggleEditServerMode() {
    setState(() {
      _isEditingServer = !_isEditingServer;
      if (!_isEditingServer) {
        // 如果退出编辑模式，恢复原来的地址
        _serverAddressController.text = AppConstants.apiDomain;
      }
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo或应用名称
                      const Icon(
                        Icons.event_note_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Meet Ease',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '便捷高效的会议管理系统',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 登录表单卡片
                      Card(
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '欢迎登录',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // 用户名输入框
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: '用户名',
                                    hintText: '请输入您的用户名',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return '请输入用户名';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // 密码输入框
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    hintText: '请输入您的密码',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return '请输入密码';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                // 登录按钮
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            '登录',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                                const SizedBox(height: 16),
                                // 注册链接
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  child: const Text(
                                    '没有账号？点击注册',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 服务器设置
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isEditingServer = !_isEditingServer;
                                });
                              },
                              child: const Icon(
                                Icons.settings,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                            if (_isEditingServer) ...[
                              const SizedBox(width: 8),
                              _isEditingServer
                                  ? SizedBox(
                                    width: 180,
                                    child: TextField(
                                      controller: _serverAddressController,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: '输入服务器地址',
                                        hintStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    '服务器: ${AppConstants.apiDomain}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                              const SizedBox(width: 8),
                              _isTestingConnection
                                  ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Row(
                                    children: [
                                      InkWell(
                                        onTap: _testServerConnection,
                                        child: const Icon(
                                          Icons.save,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: _toggleEditServerMode,
                                        child: const Icon(
                                          Icons.cancel,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
