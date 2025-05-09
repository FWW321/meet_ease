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
    // 选中的标签页索引
    final selectedTabIndex = useState<int>(0);
    // 过滤状态
    final selectedFilterState = useState<MeetingStatus?>(null);
    // 搜索查询
    final searchQueryState = useState<String>('');
    // 是否在搜索中
    final isSearchingState = useState<bool>(false);
    // 文本控制器
    final textController = useTextEditingController();

    // 根据标签页索引确定当前显示模式
    final showRecommended = selectedTabIndex.value == 0;
    final showMyPrivate = selectedTabIndex.value == 1;
    final showAll = selectedTabIndex.value == 2;

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
            ? (showMyPrivate
                ? ref.watch(
                  searchPrivateMeetingsProvider(searchQueryState.value),
                )
                : ref.watch(
                  searchPublicMeetingsProvider(searchQueryState.value),
                ))
            : showMyPrivate
            ? ref.watch(myPrivateMeetingsProvider)
            : showRecommended
            ? ref.watch(recommendedMeetingsProvider)
            : ref.watch(meetingListProvider);

    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
                }
              },
            ),
          ),

          // 搜索提示
          if (!isSearchingState.value)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
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
              padding: const EdgeInsets.all(16.0),
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

          // 标签页和筛选条件
          if (!isSearchingState.value) ...[
            // 标签页切换
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildTabButton(
                      context: context,
                      title: '推荐',
                      isSelected: showRecommended,
                      onTap: () {
                        selectedTabIndex.value = 0;
                        selectedFilterState.value = null;
                      },
                      icon: Icons.recommend,
                    ),
                    _buildTabButton(
                      context: context,
                      title: '我的',
                      isSelected: showMyPrivate,
                      onTap: () {
                        selectedTabIndex.value = 1;
                        selectedFilterState.value = null;
                      },
                      icon: Icons.person_outline,
                    ),
                    _buildTabButton(
                      context: context,
                      title: '全部',
                      isSelected: showAll,
                      onTap: () {
                        selectedTabIndex.value = 2;
                        selectedFilterState.value = null;
                      },
                      icon: Icons.list_alt,
                    ),
                  ],
                ),
              ),
            ),

            // 状态筛选器
            _buildStatusFilters(context, selectedFilterState),
          ],

          // 会议列表
          Expanded(
            child: meetingsAsync.when(
              data: (meetings) {
                // 根据选择的状态筛选会议
                final filteredMeetings =
                    selectedFilterState.value != null
                        ? meetings.where((m) {
                          if (m is Meeting) {
                            return m.status == selectedFilterState.value;
                          } else if (m is MeetingRecommendation) {
                            return m.meeting.status ==
                                selectedFilterState.value;
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
                  showRecommended,
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
              if (showMyPrivate) {
                ref.invalidate(
                  searchPrivateMeetingsProvider(searchQueryState.value),
                );
              } else {
                ref.invalidate(
                  searchPublicMeetingsProvider(searchQueryState.value),
                );
              }
            }
          }
        },
        tooltip: '创建会议',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建标签页按钮
  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建状态筛选条件
  Widget _buildStatusFilters(
    BuildContext context,
    ValueNotifier<MeetingStatus?> selectedFilter,
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
              label: const Text('全部状态'),
              selected: selectedFilter.value == null,
              onSelected: (selected) {
                if (selected) {
                  selectedFilter.value = null;
                }
              },
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      selectedFilter.value == null
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('即将开始'),
              selected: selectedFilter.value == MeetingStatus.upcoming,
              onSelected: (selected) {
                selectedFilter.value = selected ? MeetingStatus.upcoming : null;
              },
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      selectedFilter.value == MeetingStatus.upcoming
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('进行中'),
              selected: selectedFilter.value == MeetingStatus.ongoing,
              onSelected: (selected) {
                selectedFilter.value = selected ? MeetingStatus.ongoing : null;
              },
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      selectedFilter.value == MeetingStatus.ongoing
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
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
              },
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      selectedFilter.value == MeetingStatus.completed
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
          FilterChip(
            label: const Text('已取消'),
            selected: selectedFilter.value == MeetingStatus.cancelled,
            onSelected: (selected) {
              selectedFilter.value = selected ? MeetingStatus.cancelled : null;
            },
            shape: StadiumBorder(
              side: BorderSide(
                color:
                    selectedFilter.value == MeetingStatus.cancelled
                        ? Colors.transparent
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
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
          // 刷新所有可能的搜索结果
          ref.invalidate(searchPrivateMeetingsProvider(searchQuery));
          ref.invalidate(searchPublicMeetingsProvider(searchQuery));
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
