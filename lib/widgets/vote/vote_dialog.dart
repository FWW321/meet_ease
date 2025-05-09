import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_vote.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';
import '../../utils/time_utils.dart';
import '../../utils/http_utils.dart';
import '../../constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 投票对话框组件，用于显示投票内容和进行投票
class VoteDialog extends ConsumerStatefulWidget {
  final MeetingVote vote;
  final String meetingId;

  const VoteDialog({required this.vote, required this.meetingId, super.key});

  @override
  ConsumerState<VoteDialog> createState() => _VoteDialogState();
}

class _VoteDialogState extends ConsumerState<VoteDialog> {
  final selectedOptions = <String>[];
  List<VoteOption> options = [];
  bool isLoading = true;
  String? errorMessage;
  bool hasVoted = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadVoteOptions();
    _checkUserVoteStatus();
  }

  // 检查用户是否已投票
  Future<void> _checkUserVoteStatus() async {
    try {
      // 获取当前用户ID
      currentUserId = await ref.read(currentUserIdProvider.future);

      // 加载投票结果时会检查用户是否已投票
    } catch (e) {
      print('检查用户投票状态出错: $e');
    }
  }

  // 加载投票选项
  Future<void> _loadVoteOptions() async {
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final results = await service.getVoteResults(widget.vote.id);

      // 获取当前用户ID，如果尚未获取
      if (currentUserId == null) {
        currentUserId = await ref.read(currentUserIdProvider.future);
      }

      // 检查用户是否已经投票
      if (currentUserId != null) {
        for (var option in results) {
          if (option.voterIds != null &&
              option.voterIds!.contains(currentUserId)) {
            hasVoted = true;
            break;
          }
        }
      }

      setState(() {
        options = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 如果正在加载，显示加载指示器
    if (isLoading) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 24),
            Text('正在获取投票选项...', style: textTheme.titleMedium),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    // 如果加载失败，显示错误消息
    if (errorMessage != null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('加载失败'),
          ],
        ),
        content: Text(
          '获取投票选项失败: $errorMessage',
          style: textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    // 计算总票数以显示百分比
    final totalVotes = options.fold(
      0,
      (sum, option) => sum + option.votesCount,
    );

    // 检查投票是否已结束
    final now = TimeUtils.nowInShanghaiTimeZone();
    final isVoteEnded =
        widget.vote.endTime != null &&
        now.isAfter(TimeUtils.utcToShanghaiTimeZone(widget.vote.endTime!));

    // 获取剩余时间文本
    String? remainingTimeText;
    if (widget.vote.endTime != null && !isVoteEnded) {
      final endTime = TimeUtils.utcToShanghaiTimeZone(widget.vote.endTime!);
      final difference = endTime.difference(now);

      if (difference.inDays > 0) {
        remainingTimeText = '剩余 ${difference.inDays} 天';
      } else if (difference.inHours > 0) {
        remainingTimeText = '剩余 ${difference.inHours} 小时';
      } else if (difference.inMinutes > 0) {
        remainingTimeText = '剩余 ${difference.inMinutes} 分钟';
      } else {
        remainingTimeText = '即将结束';
      }
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.vote.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (remainingTimeText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isVoteEnded ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVoteEnded ? '投票已结束' : remainingTimeText,
                    style: textTheme.bodySmall?.copyWith(
                      color: isVoteEnded ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // 显示用户已参与投票的提示
          if (hasVoted)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.how_to_vote, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '您已经参与过此投票',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.vote.description != null &&
                widget.vote.description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.vote.description!,
                        style: textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.vote.type == VoteType.singleChoice
                        ? Icons.radio_button_checked
                        : Icons.check_box,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '请${widget.vote.type == VoteType.singleChoice ? "选择一项" : "选择一项或多项"}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 显示当前投票统计信息
            if (totalVotes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '当前已有 $totalVotes 人参与投票',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 显示投票选项
            if (options.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      '暂无投票选项',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Card(
                elevation: 0,
                color: colorScheme.surface,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children:
                        options.map((option) {
                          final isSelected = selectedOptions.contains(
                            option.id,
                          );

                          // 计算选项的百分比
                          final percentage =
                              totalVotes > 0
                                  ? (option.votesCount / totalVotes * 100)
                                      .toStringAsFixed(1)
                                  : '0.0';

                          // 根据百分比计算颜色强度
                          final percentValue = double.parse(percentage) / 100;
                          final progressColor = colorScheme.primary.withOpacity(
                            0.2 + (percentValue * 0.8),
                          );

                          // 创建带有计数的选项标题
                          final optionTitle = Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${option.votesCount} 票 ($percentage%)',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (widget.vote.type == VoteType.singleChoice) {
                            return Column(
                              children: [
                                RadioListTile<String>(
                                  title: optionTitle,
                                  value: option.id,
                                  groupValue:
                                      selectedOptions.isEmpty
                                          ? null
                                          : selectedOptions.first,
                                  onChanged:
                                      isVoteEnded || hasVoted
                                          ? null
                                          : (value) {
                                            setState(() {
                                              selectedOptions.clear();
                                              if (value != null) {
                                                selectedOptions.add(value);
                                              }
                                            });
                                          },
                                  activeColor: colorScheme.primary,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tileColor:
                                      isSelected
                                          ? colorScheme.primaryContainer
                                              .withOpacity(0.2)
                                          : null,
                                  selectedTileColor: colorScheme
                                      .primaryContainer
                                      .withOpacity(0.2),
                                ),
                                // 进度条显示
                                if (totalVotes > 0)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      12,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: option.votesCount / totalVotes,
                                        backgroundColor: Colors.grey[200],
                                        color: progressColor,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                if (option != options.last)
                                  Divider(height: 1, indent: 16, endIndent: 16),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: optionTitle,
                                  value: isSelected,
                                  onChanged:
                                      isVoteEnded || hasVoted
                                          ? null
                                          : (value) {
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
                                  activeColor: colorScheme.primary,
                                  checkColor: colorScheme.onPrimary,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tileColor:
                                      isSelected
                                          ? colorScheme.primaryContainer
                                              .withOpacity(0.2)
                                          : null,
                                  selectedTileColor: colorScheme
                                      .primaryContainer
                                      .withOpacity(0.2),
                                ),
                                // 进度条显示
                                if (totalVotes > 0)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      12,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: option.votesCount / totalVotes,
                                        backgroundColor: Colors.grey[200],
                                        color: progressColor,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                if (option != options.last)
                                  Divider(height: 1, indent: 16, endIndent: 16),
                              ],
                            );
                          }
                        }).toList(),
                  ),
                ),
              ),

            // 底部间距
            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('取消', style: textTheme.labelLarge),
        ),
        ElevatedButton(
          onPressed:
              isVoteEnded || selectedOptions.isEmpty || hasVoted
                  ? null
                  : () => _submitVote(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              hasVoted
                  ? const Text('已投票')
                  : (isVoteEnded ? const Text('投票已结束') : const Text('提交')),
        ),
      ],
    );
  }

  // 提交投票
  Future<void> _submitVote(BuildContext context) async {
    // 检查是否有截止时间
    if (widget.vote.endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('投票缺少有效的截止时间，无法提交'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查投票是否已经结束（当前时间已超过截止时间）
    final now = TimeUtils.nowInShanghaiTimeZone();
    if (now.isAfter(TimeUtils.utcToShanghaiTimeZone(widget.vote.endTime!))) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该投票已结束，无法参与投票'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('正在提交投票...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // 获取当前用户ID
      final userId = await ref.read(currentUserIdProvider.future);

      // 创建HTTP客户端
      final client = http.Client();

      // 准备请求URL，添加userId作为查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/vote/submit/${widget.vote.id}',
      ).replace(queryParameters: {'userId': userId});

      // 准备请求头
      final headers = HttpUtils.createHeaders();

      // 将选项ID列表作为JSON数组发送
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(selectedOptions),
      );

      // 添加日志
      print('提交投票响应: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 更新投票状态
          setState(() {
            hasVoted = true;
          });

          // 投票成功
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  const Text('投票成功！'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          // 刷新投票结果
          ref.invalidate(voteResultsProvider(widget.vote.id));
        } else {
          // 投票失败
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('投票失败: ${responseData['message'] ?? "未知错误"}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // HTTP错误
        final errorMessage = HttpUtils.extractErrorMessage(
          response,
          defaultMessage: '投票提交失败',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // 异常错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('投票失败: ${error.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
