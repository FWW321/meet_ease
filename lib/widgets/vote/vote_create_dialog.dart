import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_vote.dart';
import '../../providers/meeting_process_providers.dart';
import '../../utils/time_utils.dart';

/// 创建投票对话框组件
class VoteCreateDialog extends ConsumerStatefulWidget {
  final String meetingId;

  const VoteCreateDialog({required this.meetingId, super.key});

  @override
  ConsumerState<VoteCreateDialog> createState() => _VoteCreateDialogState();
}

class _VoteCreateDialogState extends ConsumerState<VoteCreateDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final endTimeController = TextEditingController();
  DateTime? endTime;
  VoteType voteType = VoteType.singleChoice;
  final bool isAnonymous = false; // 修改为final，默认为false
  final optionsControllers = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    endTimeController.dispose();
    for (var controller in optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

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
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        if (!context.mounted) return;
        setState(() {
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '创建投票',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

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

                // 投票类型 - 修改为更适应窄屏幕的布局
                const Text('投票类型：'),
                Row(
                  children: [
                    Flexible(
                      child: RadioListTile<VoteType>(
                        title: const Text('单选'),
                        value: VoteType.singleChoice,
                        groupValue: voteType,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            voteType = value!;
                          });
                        },
                      ),
                    ),
                    Flexible(
                      child: RadioListTile<VoteType>(
                        title: const Text('多选'),
                        value: VoteType.multipleChoice,
                        groupValue: voteType,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            voteType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // 匿名投票选项已被移除

                // 添加截止时间选择
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDateTime(context),
                  child: IgnorePointer(
                    child: TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: '截止时间',
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
                            icon: const Icon(Icons.remove_circle_outline),
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

                // 按钮部分
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _createVote(context),
                      child: const Text('创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 创建投票
  void _createVote(BuildContext context) {
    // 验证输入
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入投票标题')));
      return;
    }

    // 验证所有选项都不为空
    final options =
        optionsControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少需要两个有效选项')));
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
      id: 'vote_${TimeUtils.nowInShanghaiTimeZone().millisecondsSinceEpoch}',
      meetingId: widget.meetingId,
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
      voteNotifierProvider(vote.id, meetingId: widget.meetingId).notifier,
    );
    notifier.createNewVote(vote);

    Navigator.of(context).pop();
  }
}
