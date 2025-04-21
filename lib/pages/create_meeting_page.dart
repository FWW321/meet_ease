import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';
import '../constants/app_constants.dart';

// 简化的API用户模型
class ApiUser {
  final String userId;
  final String username;
  final String? email;
  final String? phone;

  ApiUser({
    required this.userId,
    required this.username,
    this.email,
    this.phone,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      userId: json['userId'].toString(),
      username: json['username'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

// API用户搜索响应
class UserSearchResponse {
  final int code;
  final String message;
  final List<ApiUser> data;

  UserSearchResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data:
          (json['data'] as List<dynamic>)
              .map((e) => ApiUser.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

// 用户搜索组件 - 使用StatefulWidget隔离状态
class UserSearchWidget extends StatefulWidget {
  final List<String> selectedUserIds;
  final ValueChanged<List<String>> onSelectedUsersChanged;

  const UserSearchWidget({
    Key? key,
    required this.selectedUserIds,
    required this.onSelectedUsersChanged,
  }) : super(key: key);

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<ApiUser> _searchResults = [];
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // 搜索用户方法
  void _searchUsers(String query) {
    // 取消之前的计时器
    _searchDebounce?.cancel();

    // 如果查询为空，清空结果
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // 设置新计时器进行防抖
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
      });

      try {
        // 构建URL
        final uri = Uri.parse(
          '${AppConstants.apiBaseUrl}/user/search',
        ).replace(queryParameters: {'username': query});

        // 发送请求
        final response = await http.get(uri);

        // 处理响应
        if (response.statusCode == 200) {
          final searchResponse = UserSearchResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );

          if (mounted) {
            setState(() {
              _searchResults = searchResponse.data;
              _isSearching = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
          }
        }
      } catch (e) {
        // 处理错误
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  // 检查用户是否已选择
  bool _isUserSelected(String userId) {
    return widget.selectedUserIds.contains(userId);
  }

  // 切换用户选择状态
  void _toggleUserSelection(String userId) {
    final currentSelected = List<String>.from(widget.selectedUserIds);

    if (currentSelected.contains(userId)) {
      currentSelected.remove(userId);
    } else {
      currentSelected.add(userId);
    }

    widget.onSelectedUsersChanged(currentSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择可参与的用户',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // 用户搜索框
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索用户...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          controller: _searchController,
          onChanged: (value) {
            _searchQuery = value;
            _searchUsers(value);
          },
        ),
        const SizedBox(height: 8),

        // 用户选择列表 - 只有当搜索结果不为空时才显示
        if (_isSearching || _searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300, // 设置最大高度为300
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      shrinkWrap: true, // 使ListView高度适应内容
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return CheckboxListTile(
                          title: Text(
                            user.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user.userId}'),
                              if (user.email != null && user.email!.isNotEmpty)
                                Text('邮箱: ${user.email}'),
                              if (user.phone != null && user.phone!.isNotEmpty)
                                Text('电话: ${user.phone}'),
                            ],
                          ),
                          isThreeLine: true,
                          dense: true,
                          value: _isUserSelected(user.userId),
                          onChanged: (_) => _toggleUserSelection(user.userId),
                        );
                      },
                    ),
          )
        else if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Text(
                '未找到匹配的用户',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),

        // 已选用户提示
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child:
              widget.selectedUserIds.isEmpty
                  ? const Text(
                    '请至少选择一名用户',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  )
                  : Text(
                    '已选择 ${widget.selectedUserIds.length} 名用户',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
        ),
      ],
    );
  }
}

class CreateMeetingPage extends HookConsumerWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();

    // 表单字段控制器
    final titleController = useTextEditingController();
    final locationController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final passwordController = useTextEditingController();

    // 日期和时间
    final startDate = useState(DateTime.now().add(const Duration(hours: 1)));
    final endDate = useState(DateTime.now().add(const Duration(hours: 2)));

    // 会议类型和可见性
    final meetingType = useState(MeetingType.regular);
    final meetingVisibility = useState(MeetingVisibility.public);

    // 是否启用密码
    final enablePassword = useState(false);

    // 选中的用户列表
    final selectedUserIds = useState<List<String>>([]);

    // 创建会议状态
    final createMeetingState = ref.watch(createMeetingProvider);

    // 监听创建状态的改变
    ref.listen(createMeetingProvider, (previous, next) {
      next.whenData((meeting) {
        if (meeting != null && previous?.value != meeting) {
          // 成功创建会议，返回上一页
          Navigator.of(context).pop(true);

          // 显示成功信息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('会议创建成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });

      // 显示错误信息
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('创建失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('创建会议')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 会议标题
            TextFormField(
              controller: titleController,
              maxLength: 50, // 限制标题最大长度为50个字符
              decoration: const InputDecoration(
                labelText: '会议标题',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                counterText: '', // 隐藏内置的字符计数
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议标题';
                }
                if (value.trim().length < 3) {
                  return '会议标题至少需要3个字符';
                }
                if (value.trim().length > 50) {
                  return '会议标题不能超过50个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议地点
            TextFormField(
              controller: locationController,
              maxLength: 100, // 限制地点最大长度
              decoration: const InputDecoration(
                labelText: '会议地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入会议地点';
                }
                if (value.trim().length < 2) {
                  return '会议地点至少需要2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 会议类型选择
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '会议类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MeetingType>(
                  value: meetingType.value,
                  isExpanded: true,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      meetingType.value = newValue;
                    }
                  },
                  items:
                      MeetingType.values.map((type) {
                        return DropdownMenuItem<MeetingType>(
                          value: type,
                          child: Text(getMeetingTypeText(type)),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 会议可见性选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '会议可见性',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.visibility),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MeetingVisibility>(
                      value: meetingVisibility.value,
                      isExpanded: true,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          meetingVisibility.value = newValue;

                          // 重置已选用户列表，当可见性从私有变为其他类型时
                          if (newValue != MeetingVisibility.private) {
                            selectedUserIds.value = [];
                          }
                        }
                      },
                      items:
                          MeetingVisibility.values.map((visibility) {
                            return DropdownMenuItem<MeetingVisibility>(
                              value: visibility,
                              child: Text(getMeetingVisibilityText(visibility)),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 不同可见性的提示信息
                _buildVisibilityHelperText(meetingVisibility.value),
              ],
            ),
            const SizedBox(height: 16),

            // 会议密码设置
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '会议密码',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: enablePassword.value,
                          onChanged: (value) {
                            enablePassword.value = value;
                            if (!value) {
                              passwordController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    if (enablePassword.value)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true, // 隐藏密码
                            decoration: const InputDecoration(
                              labelText: '设置密码',
                              hintText: '参会者需要输入此密码才能加入会议',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入会议密码';
                              }
                              if (value.length < 4) {
                                return '密码长度至少为4位';
                              }
                              if (value.length > 16) {
                                return '密码长度不能超过16位';
                              }
                              // 验证密码格式，可以根据需要增加字母、数字等要求
                              if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                                return '密码只能包含字母和数字';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '启用密码后，参会者需要输入正确的密码才能加入会议。',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    else
                      const Text(
                        '不启用密码，所有参会者可直接加入会议。',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 当选择私有会议时，显示用户选择列表
            if (meetingVisibility.value == MeetingVisibility.private)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 使用独立的用户搜索组件
                  UserSearchWidget(
                    selectedUserIds: selectedUserIds.value,
                    onSelectedUsersChanged: (newSelectedUsers) {
                      selectedUserIds.value = newSelectedUsers;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // 开始时间选择
            InkWell(
              onTap: () => _selectDateTime(context, startDate, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '开始时间',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(startDate.value),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 结束时间选择
            InkWell(
              onTap: () => _selectDateTime(context, endDate, false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '结束时间',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(endDate.value),
                ),
              ),
            ),

            // 时间验证错误提示
            if (endDate.value.isBefore(startDate.value) ||
                endDate.value.isAtSameMomentAs(startDate.value))
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '结束时间必须晚于开始时间',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // 检查会议时长是否合理
            if (endDate.value.difference(startDate.value).inMinutes < 15)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '会议时长至少需要15分钟',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            if (endDate.value.difference(startDate.value).inHours > 24)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text(
                  '会议时长不建议超过24小时',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // 会议描述
            TextFormField(
              controller: descriptionController,
              maxLength: 500, // 限制描述最大长度
              decoration: const InputDecoration(
                labelText: '会议描述',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return '会议描述不能超过500个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 创建按钮
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ElevatedButton(
                onPressed:
                    createMeetingState.isLoading
                        ? null
                        : () async {
                          bool isValid = formKey.currentState!.validate();

                          // 额外验证
                          // 1. 检查结束时间是否晚于开始时间
                          if (endDate.value.isBefore(startDate.value) ||
                              endDate.value.isAtSameMomentAs(startDate.value)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('结束时间必须晚于开始时间'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          // 2. 检查会议时长是否至少15分钟
                          final duration = endDate.value.difference(
                            startDate.value,
                          );
                          if (duration.inMinutes < 15) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('会议时长至少需要15分钟'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          // 3. 如果是私有会议，必须选择至少一名用户
                          if (meetingVisibility.value ==
                                  MeetingVisibility.private &&
                              selectedUserIds.value.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('私有会议必须选择至少一名用户'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            isValid = false;
                          }

                          if (isValid) {
                            // 调用创建会议方法
                            final notifier = ref.read(
                              createMeetingProvider.notifier,
                            );

                            await notifier.create(
                              title: titleController.text.trim(),
                              location: locationController.text.trim(),
                              startTime: startDate.value,
                              endTime: endDate.value,
                              description: descriptionController.text.trim(),
                              type: meetingType.value,
                              visibility: meetingVisibility.value,
                              allowedUsers:
                                  meetingVisibility.value ==
                                          MeetingVisibility.private
                                      ? selectedUserIds.value
                                      : [],
                              password:
                                  enablePassword.value
                                      ? passwordController.text.trim()
                                      : null,
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    createMeetingState.isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('创建会议'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 选择日期和时间
  Future<void> _selectDateTime(
    BuildContext context,
    ValueNotifier<DateTime> dateTimeNotifier,
    bool isStartTime,
  ) async {
    final DateTime initialDate = dateTimeNotifier.value;

    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          isStartTime
              ? DateTime.now() // 开始时间不早于当前时间
              : DateTime.now(), // 结束时间不早于当前时间（实际使用时应该不早于开始时间，但这里简化处理）
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    if (!context.mounted) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;
    if (!context.mounted) return;

    // 组合日期和时间
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    dateTimeNotifier.value = newDateTime;
  }

  // 创建会议可见性提示
  Widget _buildVisibilityHelperText(MeetingVisibility visibility) {
    String helperText;
    Color color;

    switch (visibility) {
      case MeetingVisibility.public:
        helperText = '公开会议对所有人可见，所有人可参加';
        color = Colors.blue;
        break;
      case MeetingVisibility.searchable:
        helperText = '可搜索会议仅通过会议码搜索才能显示，将自动生成6位数字会议码';
        color = Colors.orange;
        break;
      case MeetingVisibility.private:
        helperText = '私有会议只对特定人员可见，需要选择参与人员';
        color = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        helperText,
        style: TextStyle(color: color, fontStyle: FontStyle.italic),
      ),
    );
  }
}

// 获取会议类型文本
String getMeetingTypeText(MeetingType type) {
  switch (type) {
    case MeetingType.regular:
      return '常规会议';
    case MeetingType.training:
      return '培训会议';
    case MeetingType.interview:
      return '面试会议';
    case MeetingType.other:
      return '其他类型';
  }
}

// 获取会议可见性文本
String getMeetingVisibilityText(MeetingVisibility visibility) {
  switch (visibility) {
    case MeetingVisibility.public:
      return '公开会议';
    case MeetingVisibility.searchable:
      return '可搜索会议';
    case MeetingVisibility.private:
      return '私有会议';
  }
}
