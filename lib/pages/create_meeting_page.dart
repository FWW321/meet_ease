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
import 'dart:math' as math;

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

// 用户搜索组件状态保持器 - 使用静态变量存储状态，使其不受组件生命周期影响
class _UserSearchStateHolder {
  // 静态实例
  static final _UserSearchStateHolder _instance =
      _UserSearchStateHolder._internal();

  factory _UserSearchStateHolder() => _instance;

  _UserSearchStateHolder._internal();

  // 状态数据
  String currentQuery = '';
  List<ApiUser> searchResults = [];
  bool isSearching = false;
  bool hasError = false;
  // 保存搜索框文本
  String searchText = '';
  // 保存已选择的用户ID
  List<String> selectedUserIds = [];
  // 保持搜索框的控制器实例，避免重建
  final TextEditingController searchController = TextEditingController();
}

// 将用户搜索组件改为StatelessWidget，使用Riverpod管理状态
class UserSelectManager extends StateNotifier<List<String>> {
  UserSelectManager([List<String>? initialState]) : super(initialState ?? []);

  void toggle(String userId) {
    if (state.contains(userId)) {
      state = List.from(state)..remove(userId);
    } else {
      state = List.from(state)..add(userId);
    }
  }

  void updateAll(List<String> newSelected) {
    state = List.from(newSelected);
  }
}

final userSelectProvider =
    StateNotifierProvider.autoDispose<UserSelectManager, List<String>>(
      (ref) => UserSelectManager([]),
    );

// 将用户搜索列表抽离为单独的小组件
class UserSearchResultList extends StatelessWidget {
  final ScrollController scrollController;
  final List<ApiUser> searchResults;
  final List<String> selectedUserIds;
  final void Function(String) onUserSelect;

  const UserSearchResultList({
    Key? key,
    required this.scrollController,
    required this.searchResults,
    required this.selectedUserIds,
    required this.onUserSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      key: const PageStorageKey<String>('userSearchListView'),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        final isSelected = selectedUserIds.contains(user.userId);

        // 将每个列表项包装在手势探测器中，自行处理点击，避免事件冒泡
        return GestureDetector(
          // 吸收所有点击事件
          behavior: HitTestBehavior.opaque,
          // 拦截点击事件，避免冒泡到父级滚动容器
          onTap: () => onUserSelect(user.userId),
          child: CheckboxListTile(
            key: ValueKey('user_${user.userId}'),
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
            value: isSelected,
            onChanged: (_) => onUserSelect(user.userId),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }
}

// 修改后的用户搜索组件，使用Riverpod管理用户选择状态
class UserSearchWidget extends ConsumerStatefulWidget {
  final List<String> initialSelectedUserIds;
  final ValueChanged<List<String>> onSelectedUsersChanged;

  const UserSearchWidget({
    Key? key,
    required this.initialSelectedUserIds,
    required this.onSelectedUsersChanged,
  }) : super(key: key);

  @override
  ConsumerState<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends ConsumerState<UserSearchWidget>
    with AutomaticKeepAliveClientMixin {
  // 使用全局状态保持器
  final _stateHolder = _UserSearchStateHolder();
  // 使用全局保持的控制器，而不是每次都创建新的
  late final ScrollController _searchResultsScrollController;
  Timer? _searchDebounce;

  @override
  bool get wantKeepAlive => true; // 保持状态

  @override
  void initState() {
    super.initState();
    // 初始化状态
    _searchResultsScrollController = ScrollController();

    // 注册实例到provider，以便在用户选择过程中能够获取到实例
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_userSearchWidgetProvider.notifier).state = this;
    });

    // 如果控制器没有文本，设置保存的文本
    if (_stateHolder.searchController.text.isEmpty &&
        _stateHolder.searchText.isNotEmpty) {
      _stateHolder.searchController.text = _stateHolder.searchText;
    }

    // 初始化选择状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 确保在build后异步执行，避免build过程中修改provider状态
      if (widget.initialSelectedUserIds.isNotEmpty) {
        ref
            .read(userSelectProvider.notifier)
            .updateAll(widget.initialSelectedUserIds);
      }
    });

    // 如果有保存的搜索结果但没有进行中的搜索，恢复状态
    if (_stateHolder.searchResults.isNotEmpty && !_stateHolder.isSearching) {
      // 无需操作，状态会在build方法中直接使用
    }
    // 如果有保存的查询但没有结果，重新执行搜索
    else if (_stateHolder.currentQuery.isNotEmpty &&
        _stateHolder.searchResults.isEmpty &&
        !_stateHolder.isSearching) {
      _performSearch(_stateHolder.currentQuery);
    }
  }

  @override
  void dispose() {
    // 清除provider中的实例引用
    if (ref.read(_userSearchWidgetProvider) == this) {
      ref.read(_userSearchWidgetProvider.notifier).state = null;
    }

    // 仅处理本地资源，不清除全局状态
    // 不要释放_stateHolder.searchController，它是全局持久化的
    _searchResultsScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(UserSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果初始选择的用户ID变化，则更新provider
    if (oldWidget.initialSelectedUserIds != widget.initialSelectedUserIds) {
      ref
          .read(userSelectProvider.notifier)
          .updateAll(widget.initialSelectedUserIds);
    }
  }

  // 搜索用户方法
  void _performSearch(String query) {
    // 保存查询和文本
    _stateHolder.currentQuery = query;
    _stateHolder.searchText = query;

    // 取消之前的计时器
    _searchDebounce?.cancel();

    // 设置搜索状态
    setState(() {
      _stateHolder.isSearching = true;
      _stateHolder.hasError = false;
    });

    // 设置新计时器进行防抖
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // 构建URL - 不传递query参数则查询所有用户
        final uri = Uri.parse('${AppConstants.apiBaseUrl}/user/search');

        // 只有在有查询内容时才添加查询参数
        final Map<String, String> queryParams = {};
        if (query.isNotEmpty) {
          queryParams['username'] = query;
        }

        final uriWithParams =
            queryParams.isNotEmpty
                ? uri.replace(queryParameters: queryParams)
                : uri;

        // 发送请求
        final response = await http.get(uriWithParams);

        // 处理响应
        if (response.statusCode == 200) {
          final searchResponse = UserSearchResponse.fromJson(
            json.decode(response.body) as Map<String, dynamic>,
          );

          // 确保查询仍然相关
          if (mounted && _stateHolder.currentQuery == query) {
            setState(() {
              _stateHolder.searchResults = searchResponse.data;
              _stateHolder.isSearching = false;
            });
          }
        } else {
          if (mounted && _stateHolder.currentQuery == query) {
            setState(() {
              _stateHolder.searchResults = [];
              _stateHolder.isSearching = false;
              _stateHolder.hasError = true;
            });
          }
        }
      } catch (e) {
        // 处理错误
        if (mounted && _stateHolder.currentQuery == query) {
          setState(() {
            _stateHolder.searchResults = [];
            _stateHolder.isSearching = false;
            _stateHolder.hasError = true;
          });
        }
      }
    });
  }

  // 切换用户选择
  void _toggleUserSelection(String userId) {
    // 保存当前滚动位置
    final currentPosition = _searchResultsScrollController.position.pixels;

    // 使用Riverpod更新状态，这不会触发TextEditingController的重建
    ref.read(userSelectProvider.notifier).toggle(userId);
    // 通过回调将选中状态传递给父组件
    widget.onSelectedUsersChanged(ref.read(userSelectProvider));

    // 使用Future.microtask确保在状态更新后恢复滚动位置
    Future.microtask(() {
      if (_searchResultsScrollController.hasClients &&
          _searchResultsScrollController.position.pixels != currentPosition) {
        _searchResultsScrollController.jumpTo(currentPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin需要

    // 读取当前选中的用户
    final selectedUsers = ref.watch(userSelectProvider);

    return RepaintBoundary(
      child: Column(
        key: const ValueKey('userSearchColumn'),
        mainAxisSize: MainAxisSize.min, // 限制为尽可能小
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择可参与的用户',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // 用户搜索框 - 使用StatefulBuilder隔离状态更新
          StatefulBuilder(
            builder: (context, setTextFieldState) {
              return TextField(
                key: const ValueKey('userSearchField'),
                decoration: const InputDecoration(
                  hintText: '搜索用户 (空白显示全部)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                controller: _stateHolder.searchController,
                onChanged: (value) {
                  // 不使用setState更新整个组件，只更新TextField
                  setTextFieldState(() {
                    _performSearch(value);
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),

          // 用户选择列表 - 只有当搜索结果不为空时才显示
          // 使用AnimatedSize平滑过渡
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child:
                _stateHolder.isSearching ||
                        _stateHolder.searchResults.isNotEmpty
                    ? Container(
                      key: const ValueKey('searchResultsContainer'),
                      constraints: const BoxConstraints(
                        maxHeight: 300, // 设置最大高度为300
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          _stateHolder.isSearching
                              ? const Center(child: CircularProgressIndicator())
                              // 使用NotificationListener阻止滚动传递到父级
                              : NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  // 吸收所有滚动通知，阻止向上传递到父级滚动视图
                                  // 这会阻止滚动行为影响父级ScrollView的位置
                                  if (notification
                                          is ScrollUpdateNotification ||
                                      notification is ScrollEndNotification ||
                                      notification is OverscrollNotification) {
                                    return true; // 阻止继续冒泡
                                  }
                                  return false; // 允许其他类型的通知通过
                                },
                                child: UserSearchResultList(
                                  scrollController:
                                      _searchResultsScrollController,
                                  searchResults: _stateHolder.searchResults,
                                  selectedUserIds: selectedUsers,
                                  onUserSelect: _toggleUserSelection,
                                ),
                              ),
                    )
                    : _stateHolder.currentQuery.isNotEmpty &&
                        _stateHolder.searchResults.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: Text(
                          _stateHolder.hasError ? '搜索出错，请重试' : '未找到匹配的用户',
                          style: TextStyle(
                            color:
                                _stateHolder.hasError
                                    ? Colors.red
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(), // 当没有搜索结果且没有查询时，不显示任何内容
          ),
        ],
      ),
    );
  }
}

// 文件顶部添加 Provider
final _userSearchWidgetProvider = StateProvider<_UserSearchWidgetState?>(
  (ref) => null,
);

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

    // 记录已选用户数量的快照，用于显示
    final selectedUsersCount = useState(0);

    // 创建会议状态
    final createMeetingState = ref.watch(createMeetingProvider);

    // 自定义滚动控制器
    final scrollController = useScrollController(keepScrollOffset: true);

    // 根据ID查找用户
    ApiUser? _findUserById(WidgetRef ref, String userId) {
      // 尝试从搜索结果中查找
      final searchWidget = ref.read(_userSearchWidgetProvider);
      if (searchWidget != null) {
        final results = searchWidget._stateHolder.searchResults;
        for (final user in results) {
          if (user.userId == userId) {
            return user;
          }
        }
      }
      // 未找到，返回null
      return null;
    }

    // 构建用户选择内容组件，处理键盘弹出导致的溢出问题
    Widget buildUserSelectionContent(List<String> initialUserIds) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Consumer(
            builder: (context, ref, _) {
              final selectedUserIds = ref.watch(userSelectProvider);

              return Column(
                children: [
                  // 搜索区域
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: UserSearchWidget(
                      initialSelectedUserIds: initialUserIds,
                      onSelectedUsersChanged: (_) {
                        // 选择变化直接反映在provider中，不需要额外处理
                      },
                    ),
                  ),

                  // 已选择用户展示区域（当有选择时显示）
                  if (selectedUserIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '已选 ${selectedUserIds.length} 名用户',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              // 清空选择按钮
                              TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(userSelectProvider.notifier)
                                      .updateAll([]);
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text(
                                  '清空',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 选中用户标签展示 - 使用SingleChildScrollView防止溢出
                          SizedBox(
                            height: 80, // 限制高度，避免占用过多空间
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    selectedUserIds.map((userId) {
                                      // 查找用户对象以显示名称
                                      final user = _findUserById(ref, userId);
                                      return InputChip(
                                        label: Text(user?.username ?? userId),
                                        onDeleted: () {
                                          ref
                                              .read(userSelectProvider.notifier)
                                              .toggle(userId);
                                        },
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.blue.shade50,
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    }

    // 选择用户的弹窗方法
    Future<void> showUserSelectionDialog() async {
      // 创建临时选择状态以便在弹窗中使用
      final tempSelectedUserIds = List<String>.from(selectedUserIds.value);

      // 重置Riverpod状态
      ref.read(userSelectProvider.notifier).updateAll(tempSelectedUserIds);

      // 保存当前UserSearchWidget实例，以便查询用户信息
      ref.read(_userSearchWidgetProvider.notifier).state = null;

      // 创建一个GlobalKey，用于获取UserSearchWidget实例并执行空查询
      final userSearchWidgetKey = GlobalKey<_UserSearchWidgetState>();

      // 创建一个Completer，用于在弹窗显示后执行空查询
      final dialogShown = Completer<void>();

      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 防止误触背景关闭对话框
        builder: (BuildContext context) {
          // 标记弹窗已显示
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!dialogShown.isCompleted) {
              dialogShown.complete();

              // 对话框显示后立即执行空查询显示所有用户
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final searchState = userSearchWidgetKey.currentState;
                if (searchState != null) {
                  searchState._performSearch('');
                }
              });
            }
          });

          // 获取屏幕尺寸
          final Size screenSize = MediaQuery.of(context).size;
          final double maxDialogWidth = math.min(
            screenSize.width * 0.85,
            450.0,
          );
          final double maxDialogHeight = math.min(
            screenSize.height * 0.75,
            600.0,
          );

          return StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: maxDialogWidth,
                    constraints: BoxConstraints(maxHeight: maxDialogHeight),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dialogBackgroundColor,
                      borderRadius: BorderRadius.circular(16), // 更大的圆角
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    // 使用SingleChildScrollView防止整个弹窗溢出
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16), // 匹配外部圆角
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 标题栏 - 固定在顶部，使用更现代的样式
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.05),
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Theme.of(context).primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '选择可参与的用户',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                // 关闭按钮
                                IconButton(
                                  icon: const Icon(Icons.close, size: 22),
                                  onPressed: () {
                                    ref
                                        .read(userSelectProvider.notifier)
                                        .updateAll(selectedUserIds.value);
                                    Navigator.of(context).pop(false);
                                  },
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 内容区域 - 使用Expanded确保内容区域自适应高度，并使用SingleChildScrollView防止内容溢出
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  12,
                                ),
                                child: UserSearchWidget(
                                  key: userSearchWidgetKey, // 使用key获取实例
                                  initialSelectedUserIds: tempSelectedUserIds,
                                  onSelectedUsersChanged: (_) {
                                    // 选择变化直接反映在provider中，不需要额外处理
                                  },
                                ),
                              ),
                            ),
                          ),

                          // 按钮区域 - 固定在底部，使用更现代的样式
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 清除选择按钮
                                Consumer(
                                  builder: (context, ref, _) {
                                    final selectedUsers =
                                        ref.watch(userSelectProvider).length;
                                    return OutlinedButton.icon(
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: Text(
                                        '清空选择${selectedUsers > 0 ? ' ($selectedUsers)' : ''}',
                                      ),
                                      onPressed:
                                          selectedUsers > 0
                                              ? () {
                                                ref
                                                    .read(
                                                      userSelectProvider
                                                          .notifier,
                                                    )
                                                    .updateAll([]);
                                              }
                                              : null,
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('确认选择'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      // 如果确认了选择，更新状态
      if (result == true) {
        final newSelectedIds = ref.read(userSelectProvider);
        selectedUserIds.value = newSelectedIds;
        selectedUsersCount.value = newSelectedIds.length;
      }
    }

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

    // 表单验证和提交
    Future<void> submitForm() async {
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
      final duration = endDate.value.difference(startDate.value);
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
      if (meetingVisibility.value == MeetingVisibility.private &&
          selectedUserIds.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('私有会议必须选择至少一名用户'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '选择用户',
              onPressed: showUserSelectionDialog,
            ),
          ),
        );
        isValid = false;
      }

      if (isValid) {
        // 调用创建会议方法
        final notifier = ref.read(createMeetingProvider.notifier);

        await notifier.create(
          title: titleController.text.trim(),
          location: locationController.text.trim(),
          startTime: startDate.value,
          endTime: endDate.value,
          description: descriptionController.text.trim(),
          type: meetingType.value,
          visibility: meetingVisibility.value,
          allowedUsers:
              meetingVisibility.value == MeetingVisibility.private
                  ? selectedUserIds.value
                  : [],
          password:
              enablePassword.value ? passwordController.text.trim() : null,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('创建会议')),
      body: Form(
        key: formKey,
        child: ListView(
          controller: scrollController,
          key: const PageStorageKey<String>('createMeetingPageScrollView'),
          padding: const EdgeInsets.all(16.0),
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
                            selectedUsersCount.value = 0;
                            // 重置Riverpod状态
                            ref.read(userSelectProvider.notifier).updateAll([]);
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

            // 用户选择区域 - 仅在私有会议时显示
            if (meetingVisibility.value == MeetingVisibility.private)
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
                          const Icon(Icons.people, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '参与用户',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.edit),
                            label: Text(
                              selectedUserIds.value.isEmpty ? '选择用户' : '修改选择',
                            ),
                            onPressed: showUserSelectionDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 只在有选择用户时显示用户信息区域
                      if (selectedUserIds.value.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '已选择 ${selectedUserIds.value.length} 名参与用户',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 如果选择用户数量较多，增加可滚动区域
                              selectedUserIds.value.length > 5
                                  ? SizedBox(
                                    height: 40,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          for (
                                            var i = 0;
                                            i < selectedUserIds.value.length;
                                            i++
                                          )
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Chip(
                                                label: Text(
                                                  'User ${i + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : Text(
                                    '点击"修改选择"按钮可编辑参与用户',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
            ElevatedButton(
              onPressed: createMeetingState.isLoading ? null : submitForm,
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
            const SizedBox(height: 32),
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
