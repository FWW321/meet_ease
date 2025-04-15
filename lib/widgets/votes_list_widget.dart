import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting_vote.dart';
import '../providers/meeting_process_providers.dart';

/// 会议投票列表组件
class VotesListWidget extends ConsumerWidget {
  final String meetingId;
  final bool isReadOnly;

  const VotesListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votesAsync = ref.watch(meetingVotesProvider(meetingId));

    return votesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '获取会议投票失败\n',
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
      data: (votes) {
        if (votes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('暂无投票'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateVoteDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('创建投票'),
                ),
              ],
            ),
          );
        }

        // 将投票按状态分组
        final activeVotes =
            votes.where((v) => v.status == VoteStatus.active).toList();
        final pendingVotes =
            votes.where((v) => v.status == VoteStatus.pending).toList();
        final closedVotes =
            votes.where((v) => v.status == VoteStatus.closed).toList();

        return Column(
          children: [
            // 标题和创建按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('会议投票', style: Theme.of(context).textTheme.titleLarge),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateVoteDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('创建投票'),
                  ),
                ],
              ),
            ),

            // 投票列表
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 进行中的投票
                  if (activeVotes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '进行中的投票',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.blue),
                      ),
                    ),
                    ...activeVotes.map(
                      (vote) => _buildVoteCard(context, vote, ref),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 待开始的投票
                  if (pendingVotes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '待开始的投票',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.orange),
                      ),
                    ),
                    ...pendingVotes.map(
                      (vote) => _buildVoteCard(context, vote, ref),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 已结束的投票
                  if (closedVotes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '已结束的投票',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ),
                    ...closedVotes.map(
                      (vote) => _buildVoteCard(context, vote, ref),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建投票卡片
  Widget _buildVoteCard(BuildContext context, MeetingVote vote, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final statusColor = _getVoteStatusColor(vote.status);
    final statusText = _getVoteStatusText(vote.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showVoteDetailDialog(context, vote, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vote.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),

              // 描述
              if (vote.description != null && vote.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vote.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              // 投票类型
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      vote.type == VoteType.singleChoice
                          ? Icons.radio_button_checked
                          : Icons.check_box,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vote.type == VoteType.singleChoice ? '单选' : '多选',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (vote.isAnonymous) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '匿名投票',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              // 创建和开始时间
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      '创建者: ${vote.creatorName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '创建于: ${dateFormat.format(vote.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              if (vote.startTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '开始于: ${dateFormat.format(vote.startTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              if (vote.endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '结束于: ${dateFormat.format(vote.endTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // 进度指示器（仅针对活动投票）
              if (vote.status == VoteStatus.active) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value:
                      vote.totalVotes > 0
                          ? vote.totalVotes / 10
                          : 0, // 假设10人参与会议
                  backgroundColor: Colors.grey[200],
                  color: Colors.blue,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '已有 ${vote.totalVotes} 人参与投票',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],

              // 操作按钮
              if (vote.status != VoteStatus.closed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (vote.status == VoteStatus.pending)
                        ElevatedButton.icon(
                          onPressed: () => _startVote(context, vote.id, ref),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('开始投票'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      if (vote.status == VoteStatus.active) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showVoteDialog(context, vote, ref),
                          icon: const Icon(Icons.how_to_vote),
                          label: const Text('投票'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _closeVote(context, vote.id, ref),
                          icon: const Icon(Icons.stop),
                          label: const Text('结束投票'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 创建投票对话框
  void _showCreateVoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    VoteType voteType = VoteType.singleChoice;
    bool isAnonymous = false;
    final optionsControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('创建投票'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: '投票标题',
                            hintText: '例如：下一次会议地点',
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: '描述 (可选)',
                            hintText: '例如：请选择下一次项目会议的地点',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        // 投票类型
                        Row(
                          children: [
                            const Text('投票类型：'),
                            Radio<VoteType>(
                              value: VoteType.singleChoice,
                              groupValue: voteType,
                              onChanged: (value) {
                                setState(() {
                                  voteType = value!;
                                });
                              },
                            ),
                            const Text('单选'),
                            const SizedBox(width: 16),
                            Radio<VoteType>(
                              value: VoteType.multipleChoice,
                              groupValue: voteType,
                              onChanged: (value) {
                                setState(() {
                                  voteType = value!;
                                });
                              },
                            ),
                            const Text('多选'),
                          ],
                        ),
                        // 匿名投票
                        SwitchListTile(
                          title: const Text('匿名投票'),
                          subtitle: const Text('投票结果不显示投票人信息'),
                          value: isAnonymous,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              isAnonymous = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // 选项
                        const Text('投票选项：'),
                        const SizedBox(height: 8),
                        ...List.generate(optionsControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: optionsControllers[index],
                                    decoration: InputDecoration(
                                      labelText: '选项 ${index + 1}',
                                      hintText: '输入选项内容',
                                    ),
                                  ),
                                ),
                                if (optionsControllers.length > 2)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        optionsControllers.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        // 添加选项按钮
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              optionsControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('添加选项'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // 验证输入
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入投票标题')),
                          );
                          return;
                        }

                        // 验证所有选项都不为空
                        final options =
                            optionsControllers
                                .map((controller) => controller.text.trim())
                                .where((text) => text.isNotEmpty)
                                .toList();

                        if (options.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('至少需要两个有效选项')),
                          );
                          return;
                        }

                        // 创建投票选项
                        final voteOptions =
                            options.map((text) {
                              return VoteOption(
                                id:
                                    'option_${DateTime.now().millisecondsSinceEpoch}_${options.indexOf(text)}',
                                text: text,
                                votesCount: 0,
                                voterIds: [],
                              );
                            }).toList();

                        // 创建投票
                        final vote = MeetingVote(
                          id: 'vote_${DateTime.now().millisecondsSinceEpoch}',
                          meetingId: meetingId,
                          title: titleController.text,
                          description:
                              descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                          type: voteType,
                          status: VoteStatus.pending,
                          isAnonymous: isAnonymous,
                          options: voteOptions,
                          totalVotes: 0,
                          creatorId: 'current_user_id', // 应从用户状态获取
                          creatorName: '当前用户', // 应从用户状态获取
                          createdAt: DateTime.now(),
                        );

                        // 创建投票
                        final notifier = ref.read(
                          voteNotifierProvider(
                            vote.id,
                            meetingId: meetingId,
                          ).notifier,
                        );
                        notifier.createNewVote(vote);

                        Navigator.of(context).pop();
                      },
                      child: const Text('创建'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 显示投票详情对话框
  void _showVoteDetailDialog(
    BuildContext context,
    MeetingVote vote,
    WidgetRef ref,
  ) {
    final resultsAsync = ref.watch(voteResultsProvider(vote.id));

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(vote.title),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vote.description != null && vote.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(vote.description!),
                    ),

                  Text(
                    '投票类型: ${vote.type == VoteType.singleChoice ? "单选" : "多选"}${vote.isAnonymous ? " (匿名)" : ""}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),

                  const Divider(height: 32),

                  if (vote.status == VoteStatus.active) ...[
                    const Text(
                      '投票正在进行中...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ] else if (vote.status == VoteStatus.pending) ...[
                    const Text(
                      '投票尚未开始',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '投票结果:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 投票结果
                  resultsAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Text(
                          '加载结果失败: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                    data: (options) {
                      final totalVotes = options.fold<int>(
                        0,
                        (sum, option) => sum + option.votesCount,
                      );

                      if (totalVotes == 0) {
                        return const Text('暂无投票数据');
                      }

                      return Column(
                        children:
                            options.map((option) {
                              final percentage =
                                  totalVotes > 0
                                      ? (option.votesCount / totalVotes * 100)
                                          .toStringAsFixed(1)
                                      : '0.0';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(option.text),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value:
                                                totalVotes > 0
                                                    ? option.votesCount /
                                                        totalVotes
                                                    : 0,
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.blue,
                                            minHeight: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$percentage% (${option.votesCount}票)',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (!vote.isAnonymous &&
                                        option.voterIds != null &&
                                        option.voterIds!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '投票人: ${option.voterIds!.join(", ")}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (vote.status == VoteStatus.pending)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startVote(context, vote.id, ref);
                  },
                  child: const Text('开始投票'),
                ),
              if (vote.status == VoteStatus.active) ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showVoteDialog(context, vote, ref);
                  },
                  child: const Text('投票'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _closeVote(context, vote.id, ref);
                  },
                  child: const Text('结束投票'),
                ),
              ],
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  // 显示投票对话框
  void _showVoteDialog(BuildContext context, MeetingVote vote, WidgetRef ref) {
    // 单选或多选的选中状态
    final selectedOptions = <String>[];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(vote.title),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vote.description != null &&
                            vote.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(vote.description!),
                          ),

                        Text(
                          '请${vote.type == VoteType.singleChoice ? "选择一项" : "选择一项或多项"}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 16),

                        // 选项列表
                        ...vote.options.map((option) {
                          final isSelected = selectedOptions.contains(
                            option.id,
                          );

                          if (vote.type == VoteType.singleChoice) {
                            return RadioListTile<String>(
                              title: Text(option.text),
                              value: option.id,
                              groupValue:
                                  selectedOptions.isEmpty
                                      ? null
                                      : selectedOptions.first,
                              onChanged: (value) {
                                setState(() {
                                  selectedOptions.clear();
                                  if (value != null) {
                                    selectedOptions.add(value);
                                  }
                                });
                              },
                            );
                          } else {
                            return CheckboxListTile(
                              title: Text(option.text),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedOptions.add(option.id);
                                  } else {
                                    selectedOptions.remove(option.id);
                                  }
                                });
                              },
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedOptions.isEmpty
                              ? null
                              : () {
                                // 提交投票
                                final voteNotifier = ref.read(
                                  voteNotifierProvider(
                                    vote.id,
                                    meetingId: meetingId,
                                  ).notifier,
                                );
                                voteNotifier.submitVote(
                                  'current_user_id',
                                  selectedOptions,
                                );
                                Navigator.of(context).pop();
                              },
                      child: const Text('提交'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 开始投票
  void _startVote(BuildContext context, String voteId, WidgetRef ref) {
    final notifier = ref.read(
      voteNotifierProvider(voteId, meetingId: meetingId).notifier,
    );
    notifier.startVote();
  }

  // 结束投票
  void _closeVote(BuildContext context, String voteId, WidgetRef ref) {
    final notifier = ref.read(
      voteNotifierProvider(voteId, meetingId: meetingId).notifier,
    );
    notifier.closeVote();
  }

  // 获取投票状态颜色
  Color _getVoteStatusColor(VoteStatus status) {
    switch (status) {
      case VoteStatus.pending:
        return Colors.orange;
      case VoteStatus.active:
        return Colors.blue;
      case VoteStatus.closed:
        return Colors.grey;
    }
  }

  // 获取投票状态文本
  String _getVoteStatusText(VoteStatus status) {
    switch (status) {
      case VoteStatus.pending:
        return '待开始';
      case VoteStatus.active:
        return '进行中';
      case VoteStatus.closed:
        return '已结束';
    }
  }
}
