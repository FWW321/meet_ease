import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/service_providers.dart';
import '../pages/login_page.dart';
import '../constants/app_constants.dart';
import '../utils/server_utils.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _serverAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      await userService.register(
        _usernameController.text,
        _passwordController.text,
        _emailController.text,
        _phoneController.text,
      );

      await AuthService.saveLoginStatus(true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('注册成功！请登录')));

      // 注册成功后跳转到登录页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注册失败: ${e.toString()}')));
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
      appBar: AppBar(title: const Text('注册')),
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
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入邮箱';
                      if (!value.contains('@')) return '请输入有效的邮箱地址';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '手机号码',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入手机号码';
                      if (value.length != 11) return '请输入11位手机号码';
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
                      if (value.length < 6) return '密码至少需要6位';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '确认密码',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请确认密码';
                      if (value != _passwordController.text) return '两次密码不一致';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('注册', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text('已有账号？点击登录'),
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
                              if (_isEditingServer) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _toggleEditServerMode,
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 14,
                                    color: Colors.red,
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
