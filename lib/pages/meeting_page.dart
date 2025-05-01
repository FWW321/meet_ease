import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../models/meeting_recommendation.dart';
import '../providers/meeting_providers.dart';
import '../widgets/meeting_list_item.dart';
import '../constants/app_constants.dart';
import 'meeting_detail_page.dart';

class MeetingPage extends HookConsumerWidget {
  const MeetingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 过滤状态
    final selectedFilterState = useState<MeetingStatus?>(null);
    // 搜索查询
    final searchQueryState = useState<String>('');
    // 是否在搜索中
    final isSearchingState = useState<bool>(false);
    // 文本控制器
    final textController = useTextEditingController();
    // 显示模式 - 添加新的状态控制是否显示推荐会议
    final showRecommendedState = useState<bool>(true);
    // 显示我的私密会议
    final showMyPrivateState = useState<bool>(false);

    // 监听搜索框变化
    useEffect(() {
      textController.addListener(() {
        if (textController.text.isEmpty && searchQueryState.value.isNotEmpty) {
          // 如果清空了搜索框，重置搜索状态
          searchQueryState.value = '';
          isSearchingState.value = false;
        }
      });
      return () => textController.dispose();
    }, [textController]);

    // 获取会议列表
    final meetingsAsync =
        isSearchingState.value && searchQueryState.value.isNotEmpty
            ? ref.watch(searchMeetingsProvider(searchQueryState.value))
            : showMyPrivateState.value
            ? ref.watch(myPrivateMeetingsProvider)
            : showRecommendedState.value
            ? ref.watch(recommendedMeetingsProvider)
            : ref.watch(meetingListProvider);

    return Scaffold(
      body: Column(
        children: [
          // 顶部操作区域
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('查看所有会议'),
                  onPressed: () {
                    Navigator.pushNamed(context, AppConstants.meetingListRoute);
                  },
                ),
              ],
            ),
          ),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: '搜索会议...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    searchQueryState.value.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            textController.clear();
                            searchQueryState.value = '';
                            isSearchingState.value = false;
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchQueryState.value = value;
                  isSearchingState.value = true;
                  // 搜索时关闭推荐模式和我的模式
                  showRecommendedState.value = false;
                  showMyPrivateState.value = false;
                }
              },
            ),
          ),

          // 搜索提示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '提示：可搜索会议只能通过6位数字会议码搜索',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),

          // 搜索状态指示
          if (isSearchingState.value && searchQueryState.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '搜索: "${searchQueryState.value}"',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('清除搜索'),
                    onPressed: () {
                      textController.clear();
                      searchQueryState.value = '';
                      isSearchingState.value = false;
                    },
                  ),
                ],
              ),
            ),

          // 过滤栏 - 增加推荐选项，并在非搜索状态下显示
          if (!isSearchingState.value)
            _buildFilterChips(
              context,
              selectedFilterState,
              showRecommendedState,
              showMyPrivateState,
            ),

          // 会议列表
          Expanded(
            child: meetingsAsync.when(
              data: (meetings) {
                // 过滤会议状态 (仅在非搜索、非推荐、非我的模式时)
                final filteredMeetings =
                    !isSearchingState.value &&
                            !showRecommendedState.value &&
                            !showMyPrivateState.value &&
                            selectedFilterState.value != null
                        ? meetings.where((m) {
                          if (m is Meeting) {
                            return m.status == selectedFilterState.value;
                          }
                          return false;
                        }).toList()
                        : meetings;

                if (filteredMeetings.isEmpty) {
                  return _buildEmptyState(
                    isSearchingState.value,
                    searchQueryState.value,
                    () {
                      textController.clear();
                      searchQueryState.value = '';
                      isSearchingState.value = false;
                    },
                  );
                }

                return _buildMeetingListView(
                  context,
                  filteredMeetings,
                  ref,
                  isSearchingState.value ? searchQueryState.value : null,
                  showRecommendedState.value,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(
                    child: SelectableText.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '获取会议列表失败\n',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          TextSpan(text: error.toString()),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 导航到创建会议页面
          final result = await Navigator.pushNamed(
            context,
            AppConstants.createMeetingRoute,
          );

          // 如果创建成功，刷新会议列表
          if (result == true) {
            ref.invalidate(meetingListProvider);
            ref.invalidate(recommendedMeetingsProvider);
            ref.invalidate(myPrivateMeetingsProvider);
            if (searchQueryState.value.isNotEmpty) {
              ref.invalidate(searchMeetingsProvider(searchQueryState.value));
            }
          }
        },
        tooltip: '创建会议',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建过滤器选择栏
  Widget _buildFilterChips(
    BuildContext context,
    ValueNotifier<MeetingStatus?> selectedFilter,
    ValueNotifier<bool> showRecommended,
    ValueNotifier<bool> showMyPrivate,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('推荐'),
              selected: showRecommended.value,
              selectedColor: Colors.blue.withAlpha(40),
              onSelected: (selected) {
                showRecommended.value = selected;
                // 选择推荐时，清除状态过滤，关闭我的
                if (selected) {
                  selectedFilter.value = null;
                  showMyPrivate.value = false;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('我的'),
              selected: showMyPrivate.value,
              selectedColor: Colors.green.withAlpha(40),
              onSelected: (selected) {
                showMyPrivate.value = selected;
                // 选择我的时，清除状态过滤，关闭推荐
                if (selected) {
                  selectedFilter.value = null;
                  showRecommended.value = false;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('全部'),
              selected:
                  selectedFilter.value == null &&
                  !showRecommended.value &&
                  !showMyPrivate.value,
              onSelected: (selected) {
                selectedFilter.value = null;
                // 选择全部时，关闭推荐模式和我的模式
                if (selected) {
                  showRecommended.value = false;
                  showMyPrivate.value = false;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('即将开始'),
              selected: selectedFilter.value == MeetingStatus.upcoming,
              onSelected: (selected) {
                selectedFilter.value = selected ? MeetingStatus.upcoming : null;
                // 选择状态过滤时，关闭推荐模式和我的模式
                if (selected) {
                  showRecommended.value = false;
                  showMyPrivate.value = false;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('进行中'),
              selected: selectedFilter.value == MeetingStatus.ongoing,
              onSelected: (selected) {
                selectedFilter.value = selected ? MeetingStatus.ongoing : null;
                // 选择状态过滤时，关闭推荐模式和我的模式
                if (selected) {
                  showRecommended.value = false;
                  showMyPrivate.value = false;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('已结束'),
              selected: selectedFilter.value == MeetingStatus.completed,
              onSelected: (selected) {
                selectedFilter.value =
                    selected ? MeetingStatus.completed : null;
                // 选择状态过滤时，关闭推荐模式和我的模式
                if (selected) {
                  showRecommended.value = false;
                  showMyPrivate.value = false;
                }
              },
            ),
          ),
          FilterChip(
            label: const Text('已取消'),
            selected: selectedFilter.value == MeetingStatus.cancelled,
            onSelected: (selected) {
              selectedFilter.value = selected ? MeetingStatus.cancelled : null;
              // 选择状态过滤时，关闭推荐模式和我的模式
              if (selected) {
                showRecommended.value = false;
                showMyPrivate.value = false;
              }
            },
          ),
        ],
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState(
    bool isSearching,
    String searchQuery,
    VoidCallback onClearSearch,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          if (isSearching && searchQuery.isNotEmpty)
            Text(
              '没有找到包含"$searchQuery"的会议',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            )
          else
            const Text(
              '没有找到会议',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          if (isSearching && searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onClearSearch,
              child: const Text('返回全部会议'),
            ),
          ],
        ],
      ),
    );
  }

  // 构建会议列表视图
  Widget _buildMeetingListView(
    BuildContext context,
    List<dynamic> meetings,
    WidgetRef ref,
    String? searchQuery,
    bool isRecommended,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // 刷新数据
        if (searchQuery != null && searchQuery.isNotEmpty) {
          ref.invalidate(searchMeetingsProvider(searchQuery));
        } else if (isRecommended) {
          ref.invalidate(recommendedMeetingsProvider);
        } else {
          ref.invalidate(meetingListProvider);
          ref.invalidate(myPrivateMeetingsProvider);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          // 获取会议对象，可能是Meeting或MeetingRecommendation
          final meetingObj = meetings[index];
          final Meeting meeting;
          String? matchScore;

          if (meetingObj is MeetingRecommendation) {
            meeting = meetingObj.meeting;
            // 将匹配度转换为百分比
            matchScore = '${(meetingObj.matchScore * 100).toStringAsFixed(0)}%';
          } else {
            meeting = meetingObj as Meeting;
          }

          return MeetingListItem(
            meeting: meeting,
            matchScore: matchScore,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MeetingDetailPage(meetingId: meeting.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
