import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';
import '../providers/user_providers.dart';

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
class UserSearchResultList extends ConsumerWidget {
  final ScrollController scrollController;
  final List<ApiUser> searchResults;
  final List<String> selectedUserIds;
  final void Function(String) onUserSelect;

  const UserSearchResultList({
    super.key,
    required this.scrollController,
    required this.searchResults,
    required this.selectedUserIds,
    required this.onUserSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前登录用户ID
    final currentUserIdAsync = ref.watch(currentLoggedInUserIdProvider);

    return currentUserIdAsync.when(
      data: (currentUserId) {
        // 过滤掉当前用户和系统用户(userId为0)
        final filteredResults =
            searchResults
                .where(
                  (user) => user.userId != currentUserId && user.userId != '0',
                )
                .toList();

        // 对搜索结果进行处理，将已选择的用户置顶
        final List<ApiUser> sortedResults = _getSortedResults(
          filteredResults,
          selectedUserIds,
        );

        if (filteredResults.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('没有可选的用户', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          key: const PageStorageKey<String>('userSearchListView'),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: sortedResults.length,
          itemBuilder: (context, index) {
            final user = sortedResults[index];
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
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  overflow: TextOverflow.ellipsis, // 防止文本溢出
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用Flexible或Expanded包装可能溢出的文本
                    Text(
                      'ID: ${user.userId}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email != null && user.email!.isNotEmpty)
                      Text(
                        '邮箱: ${user.email}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Text(
                        '电话: ${user.phone}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                isThreeLine: true,
                dense: true,
                value: isSelected,
                onChanged: (_) => onUserSelect(user.userId),
                controlAffinity: ListTileControlAffinity.leading,
                // 为已选择项添加背景色
                tileColor:
                    isSelected
                        ? Theme.of(context).primaryColor.withAlpha(13)
                        : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (_, __) => const Center(
            child: Text('获取用户信息失败', style: TextStyle(color: Colors.red)),
          ),
    );
  }

  // 获取排序后的结果，已选择的用户置顶
  List<ApiUser> _getSortedResults(
    List<ApiUser> results,
    List<String> selectedIds,
  ) {
    if (selectedIds.isEmpty) {
      return List.from(results);
    }

    // 将结果分为已选择和未选择两组
    final List<ApiUser> selectedUsers = [];
    final List<ApiUser> unselectedUsers = [];

    for (final user in results) {
      if (selectedIds.contains(user.userId)) {
        selectedUsers.add(user);
      } else {
        unselectedUsers.add(user);
      }
    }

    // 合并两组，已选择的在前面
    return [...selectedUsers, ...unselectedUsers];
  }
}

// 用户搜索组件 widget 实例 provider
final _userSearchWidgetProvider = StateProvider<_UserSearchWidgetState?>(
  (ref) => null,
);

// 修改后的用户搜索组件，使用Riverpod管理用户选择状态
class UserSearchWidget extends ConsumerStatefulWidget {
  final List<String> initialSelectedUserIds;
  final ValueChanged<List<String>> onSelectedUsersChanged;

  const UserSearchWidget({
    super.key,
    required this.initialSelectedUserIds,
    required this.onSelectedUsersChanged,
  });

  @override
  ConsumerState<UserSearchWidget> createState() => _UserSearchWidgetState();
}

// 搜索触发通知
class SearchTriggerNotification extends Notification {
  final String query;
  SearchTriggerNotification(this.query);
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
    // 如果没有任何查询历史，自动执行空查询以显示所有用户
    else if (_stateHolder.searchResults.isEmpty) {
      // 延迟执行，确保组件已完全挂载
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch('');
      });
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

  // 搜索用户方法 - 修改为公开方法，方便外部调用
  void performSearch(String query) {
    // 更新搜索框文本
    if (_stateHolder.searchController.text != query) {
      _stateHolder.searchController.text = query;
    }

    // 调用内部搜索方法
    _performSearch(query);
  }

  // 内部搜索用户方法
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

    // 监听搜索触发通知
    return NotificationListener<SearchTriggerNotification>(
      onNotification: (notification) {
        performSearch(notification.query);
        return true; // 阻止通知继续冒泡
      },
      child: _buildContent(),
    );
  }

  // 构建内容
  Widget _buildContent() {
    // 读取当前选中的用户
    final selectedUsers = ref.watch(userSelectProvider);
    final currentUserIdAsync = ref.watch(currentLoggedInUserIdProvider);

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
                  hintText: '搜索用户',
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

          // 已选用户数量显示
          currentUserIdAsync.when(
            data: (currentUserId) {
              // 计算不包括当前用户的选中数量
              final actualSelectedCount =
                  selectedUsers.where((id) => id != currentUserId).length;

              return actualSelectedCount > 0
                  ? Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '已选择 $actualSelectedCount 名用户',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

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
