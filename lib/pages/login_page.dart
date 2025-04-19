import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/service_providers.dart';
import '../pages/home_page.dart';
import '../pages/register_page.dart';
import '../constants/app_constants.dart';
import '../utils/server_utils.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverAddressController =
      TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _isEditingServer = false;

  @override
  void initState() {
    super.initState();
    _serverAddressController.text = AppConstants.apiDomain;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用UserService进行远程登录
      final userService = ref.read(userServiceProvider);
      await userService.login(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入用户名';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入密码';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                            : const Text('登录', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text('没有账号？点击注册'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isEditingServer
                          ? SizedBox(
                            width: 200,
                            height: 40,
                            child: TextField(
                              controller: _serverAddressController,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                                isDense: true,
                                hintText: '输入服务器地址',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                          )
                          : Text(
                            '服务器地址: ${AppConstants.apiDomain}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      const SizedBox(width: 8),
                      _isTestingConnection
                          ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Row(
                            children: [
                              InkWell(
                                onTap:
                                    _isEditingServer
                                        ? _testServerConnection
                                        : _toggleEditServerMode,
                                child: Icon(
                                  _isEditingServer ? Icons.save : Icons.edit,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ),
                              if (!_isEditingServer) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _testServerConnection,
                                  child: const Icon(
                                    Icons.sync,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
