import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting_vote.dart';
import '../providers/meeting_process_providers.dart';
import '../providers/user_providers.dart';
import '../utils/time_utils.dart';

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
        final now = TimeUtils.nowInShanghaiTimeZone();
        final groupedVotes =
            votes.map((vote) {
              // 根据截止时间自动确定状态
              if (vote.status == VoteStatus.active &&
                  vote.endTime != null &&
                  now.isAfter(TimeUtils.utcToShanghaiTimeZone(vote.endTime!))) {
                // 如果当前时间超过了截止时间，则自动视为已结束
                return vote.copyWith(status: VoteStatus.closed);
              }
              return vote;
            }).toList();

        final activeVotes =
            groupedVotes.where((v) => v.status == VoteStatus.active).toList();
        final pendingVotes =
            groupedVotes.where((v) => v.status == VoteStatus.pending).toList();
        final closedVotes =
            groupedVotes.where((v) => v.status == VoteStatus.closed).toList();

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
    final statusColor = _getVoteStatusColor(vote.status);
    final statusText = _getVoteStatusText(vote.status);

    // 判断是否可以投票（进行中状态且未过截止时间）
    final now = TimeUtils.nowInShanghaiTimeZone();
    final bool canVote =
        vote.status == VoteStatus.active &&
        (vote.endTime == null ||
            now.isBefore(TimeUtils.utcToShanghaiTimeZone(vote.endTime!)));

    return InkWell(
      onTap: canVote ? () => _showVoteDialog(context, vote, ref) : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
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

              // 保留开始和结束时间
              if (vote.startTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '开始于: ${TimeUtils.formatDateTime(TimeUtils.utcToShanghaiTimeZone(vote.startTime!), format: 'yyyy-MM-dd HH:mm')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              if (vote.endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '截止于: ${TimeUtils.formatDateTime(TimeUtils.utcToShanghaiTimeZone(vote.endTime!), format: 'yyyy-MM-dd HH:mm')}',
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

              // 操作按钮（仅保留开始投票按钮）
              if (vote.status == VoteStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _startVote(context, vote.id, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始投票'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // 如果是活动状态，添加提示文字
              if (vote.status == VoteStatus.active)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '点击卡片参与投票',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
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

    // 添加截止时间选择
    DateTime? endTime;
    final endTimeController = TextEditingController();

    // 选择日期时间的辅助函数
    Future<void> _selectDateTime(BuildContext context) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: TimeUtils.nowInShanghaiTimeZone().add(
          const Duration(days: 1),
        ),
        firstDate: TimeUtils.nowInShanghaiTimeZone(),
        lastDate: TimeUtils.nowInShanghaiTimeZone().add(
          const Duration(days: 365),
        ),
      );

      if (pickedDate != null) {
        // ignore: use_build_context_synchronously
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          endTimeController.text = TimeUtils.formatDateTime(
            endTime!,
            format: 'yyyy-MM-dd HH:mm',
          );
        }
      }
    }

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

                        // 添加截止时间选择
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _selectDateTime(context),
                          child: IgnorePointer(
                            child: TextField(
                              controller: endTimeController,
                              decoration: const InputDecoration(
                                labelText: '截止时间 (可选)',
                                hintText: '选择投票截止时间',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
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
                                    'option_${TimeUtils.nowInShanghaiTimeZone().millisecondsSinceEpoch}_${options.indexOf(text)}',
                                text: text,
                                votesCount: 0,
                                voterIds: [],
                              );
                            }).toList();

                        // 创建投票
                        final vote = MeetingVote(
                          id:
                              'vote_${TimeUtils.nowInShanghaiTimeZone().millisecondsSinceEpoch}',
                          meetingId: meetingId,
                          title: titleController.text,
                          description:
                              descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                          type: voteType,
                          status: VoteStatus.pending,
                          isAnonymous: isAnonymous,
                          endTime: endTime,
                          options: voteOptions,
                          totalVotes: 0,
                          creatorId: 'default', // 使用默认值
                          creatorName: '未知用户', // 使用默认值
                          createdAt: TimeUtils.nowInShanghaiTimeZone(),
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

  // 显示投票对话框
  void _showVoteDialog(BuildContext context, MeetingVote vote, WidgetRef ref) {
    // 检查投票是否已经结束（当前时间已超过截止时间）
    final now = TimeUtils.nowInShanghaiTimeZone();
    if (vote.endTime != null &&
        now.isAfter(TimeUtils.utcToShanghaiTimeZone(vote.endTime!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该投票已结束，无法参与投票'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 直接获取投票选项数据，而不是在对话框中使用AsyncValue
    final service = ref.read(meetingProcessServiceProvider);

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在获取投票选项...'),
              ],
            ),
          ),
    );

    // 先获取选项
    service
        .getVoteResults(vote.id)
        .then((options) {
          // 关闭加载对话框
          Navigator.of(context).pop();

          // 显示投票对话框
          _showActualVoteDialog(context, vote, ref, options);
        })
        .catchError((error) {
          // 关闭加载对话框
          Navigator.of(context).pop();

          // 显示错误
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取投票选项失败: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  // 显示实际的投票对话框，已经有选项数据
  void _showActualVoteDialog(
    BuildContext context,
    MeetingVote vote,
    WidgetRef ref,
    List<VoteOption> options,
  ) {
    // 单选或多选的选中状态
    final selectedOptions = <String>[];

    // 计算总票数以显示百分比
    final totalVotes = options.fold(
      0,
      (sum, option) => sum + option.votesCount,
    );

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

                        // 显示当前投票统计信息
                        if (totalVotes > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              '当前已有 $totalVotes 人参与投票',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 显示投票选项
                        if (options.isEmpty)
                          const Text('暂无投票选项')
                        else
                          Column(
                            children:
                                options.map((option) {
                                  final isSelected = selectedOptions.contains(
                                    option.id,
                                  );

                                  // 计算选项的百分比
                                  final percentage =
                                      totalVotes > 0
                                          ? (option.votesCount /
                                                  totalVotes *
                                                  100)
                                              .toStringAsFixed(1)
                                          : '0.0';

                                  // 创建带有计数的选项标题
                                  final optionTitle = Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(option.text)),
                                      Text(
                                        '${option.votesCount} 票 ($percentage%)',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );

                                  if (vote.type == VoteType.singleChoice) {
                                    return Column(
                                      children: [
                                        RadioListTile<String>(
                                          title: optionTitle,
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
                                        ),
                                        // 进度条显示
                                        if (totalVotes > 0)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            child: LinearProgressIndicator(
                                              value:
                                                  option.votesCount /
                                                  totalVotes,
                                              backgroundColor: Colors.grey[200],
                                              minHeight: 6,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          title: optionTitle,
                                          value: isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedOptions.add(option.id);
                                              } else {
                                                selectedOptions.remove(
                                                  option.id,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        // 进度条显示
                                        if (totalVotes > 0)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            child: LinearProgressIndicator(
                                              value:
                                                  option.votesCount /
                                                  totalVotes,
                                              backgroundColor: Colors.grey[200],
                                              minHeight: 6,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  }
                                }).toList(),
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
                      onPressed:
                          selectedOptions.isEmpty
                              ? null
                              : () {
                                // 再次检查投票是否已经结束（当前时间已超过截止时间）
                                final now = TimeUtils.nowInShanghaiTimeZone();
                                if (vote.endTime != null &&
                                    now.isAfter(
                                      TimeUtils.utcToShanghaiTimeZone(
                                        vote.endTime!,
                                      ),
                                    )) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('该投票已结束，无法参与投票'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // 提交投票
                                final voteNotifier = ref.read(
                                  voteNotifierProvider(
                                    vote.id,
                                    meetingId: meetingId,
                                  ).notifier,
                                );

                                // 获取当前用户ID并提交投票
                                ref
                                    .read(currentUserIdProvider.future)
                                    .then((userId) {
                                      // 显示加载指示器
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('正在提交投票...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );

                                      // 提交投票
                                      voteNotifier
                                          .submitVote(userId, selectedOptions)
                                          .then((_) {
                                            // 投票成功
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('投票成功！'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );

                                            // 刷新投票结果
                                            ref.invalidate(
                                              voteResultsProvider(vote.id),
                                            );
                                          })
                                          .catchError((error) {
                                            // 投票失败
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '投票失败: ${error.toString()}',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          });
                                    })
                                    .catchError((error) {
                                      // 获取用户ID失败
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '获取用户信息失败: ${error.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    });
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
