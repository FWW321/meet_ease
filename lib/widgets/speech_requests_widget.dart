import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/speech_request.dart';
import '../providers/speech_request_providers.dart';

class SpeechRequestsWidget extends ConsumerStatefulWidget {
  final String meetingId;
  final bool isOrganizer;

  const SpeechRequestsWidget({
    required this.meetingId,
    required this.isOrganizer,
    super.key,
  });

  @override
  ConsumerState<SpeechRequestsWidget> createState() =>
      _SpeechRequestsWidgetState();
}

class _SpeechRequestsWidgetState extends ConsumerState<SpeechRequestsWidget> {
  // 文本控制器
  final _topicController = TextEditingController();
  final _reasonController = TextEditingController();

  // 预计发言时间（分钟）
  int _durationMinutes = 5;

  // 当前是否显示申请表单
  bool _showRequestForm = false;

  @override
  void dispose() {
    _topicController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取发言申请列表
    final speechRequestsAsync = ref.watch(
      meetingSpeechRequestsProvider(widget.meetingId),
    );

    // 获取当前正在进行的发言
    final currentSpeechAsync = ref.watch(
      currentSpeechProvider(widget.meetingId),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(meetingSpeechRequestsProvider(widget.meetingId));
          ref.invalidate(currentSpeechProvider(widget.meetingId));
        },
        child: CustomScrollView(
          slivers: [
            // 当前发言部分
            SliverToBoxAdapter(child: _buildCurrentSpeech(currentSpeechAsync)),

            // 发言申请表单
            if (_showRequestForm)
              SliverToBoxAdapter(child: _buildRequestForm()),

            // 发言申请列表
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '发言申请列表',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!_showRequestForm)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showRequestForm = true;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('申请发言'),
                      ),
                  ],
                ),
              ),
            ),

            // 发言申请列表内容
            speechRequestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('暂无发言申请')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final request = requests[index];
                    return _buildRequestItem(request);
                  }, childCount: requests.length),
                );
              },
              loading:
                  () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, stackTrace) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SelectableText.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '获取发言申请列表失败\n',
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
      ),
    );
  }

  // 构建当前发言部分
  Widget _buildCurrentSpeech(AsyncValue<SpeechRequest?> currentSpeechAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '当前发言',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              currentSpeechAsync.when(
                data: (speech) {
                  if (speech == null) {
                    return const Center(child: Text('当前没有正在进行的发言'));
                  }

                  // 计算已经发言的时间
                  final startTime = speech.startTime!;
                  final duration = DateTime.now().difference(startTime);
                  final minutes = duration.inMinutes;
                  final seconds = duration.inSeconds % 60;
                  final durationText = '$minutes分$seconds秒';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发言人: ${speech.requesterName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('主题: ${speech.topic}'),
                      if (speech.reason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('原因: ${speech.reason}'),
                        ),
                      const SizedBox(height: 8),
                      Text('预计时长: ${speech.estimatedDuration.inMinutes}分钟'),
                      const SizedBox(height: 8),
                      Text('已发言: $durationText'),
                      const SizedBox(height: 16),
                      if (widget.isOrganizer ||
                          speech.requesterId == 'currentUserId')
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _endSpeech(speech.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('结束发言'),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(
                      child: SelectableText.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '获取当前发言信息失败\n',
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
            ],
          ),
        ),
      ),
    );
  }

  // 构建申请表单
  Widget _buildRequestForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '申请发言',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showRequestForm = false;
                        _topicController.clear();
                        _reasonController.clear();
                        _durationMinutes = 5;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: '发言主题',
                  hintText: '请输入发言主题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: '发言原因（可选）',
                  hintText: '请输入发言原因',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('预计发言时长: '),
                  Expanded(
                    child: Slider(
                      value: _durationMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_durationMinutes分钟',
                      onChanged: (value) {
                        setState(() {
                          _durationMinutes = value.round();
                        });
                      },
                    ),
                  ),
                  Text('$_durationMinutes分钟'),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _submitSpeechRequest,
                  child: const Text('提交申请'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建申请项
  Widget _buildRequestItem(SpeechRequest request) {
    final statusColor = getSpeechRequestStatusColor(request.status);
    final statusText = getSpeechRequestStatusText(request.status);
    final dateFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.topic,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(request.requesterName),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${request.estimatedDuration.inMinutes}分钟'),
              ],
            ),
            if (request.reason != null && request.reason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('原因: ${request.reason}'),
              ),
            const SizedBox(height: 8),
            Text(
              '申请时间: ${dateFormat.format(request.requestTime)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (widget.isOrganizer &&
                request.status == SpeechRequestStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectRequest(request.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('拒绝'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveRequest(request.id),
                      child: const Text('批准'),
                    ),
                  ],
                ),
              ),
            if (request.status == SpeechRequestStatus.approved &&
                request.startTime == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => _startSpeech(request.id),
                    child: const Text('开始发言'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 提交发言申请
  Future<void> _submitSpeechRequest() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入发言主题')));
      return;
    }

    try {
      await ref
          .read(speechRequestCreatorProvider.notifier)
          .createSpeechRequest(
            meetingId: widget.meetingId,
            requesterId: 'currentUserId', // 替换为实际用户ID
            requesterName: '当前用户', // 替换为实际用户名
            topic: topic,
            reason: _reasonController.text.trim(),
            estimatedDuration: Duration(minutes: _durationMinutes),
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('发言申请已提交')));
        setState(() {
          _showRequestForm = false;
          _topicController.clear();
          _reasonController.clear();
          _durationMinutes = 5;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发言申请提交失败: ${e.toString()}')));
      }
    }
  }

  // 批准发言申请
  Future<void> _approveRequest(String requestId) async {
    try {
      await ref
          .read(speechRequestManagerProvider(requestId).notifier)
          .approve(
            meetingId: widget.meetingId,
            approverId: 'currentUserId', // 替换为实际用户ID
            approverName: '当前用户', // 替换为实际用户名
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已批准发言申请')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('批准发言申请失败: ${e.toString()}')));
      }
    }
  }

  // 拒绝发言申请
  Future<void> _rejectRequest(String requestId) async {
    try {
      await ref
          .read(speechRequestManagerProvider(requestId).notifier)
          .reject(
            meetingId: widget.meetingId,
            approverId: 'currentUserId', // 替换为实际用户ID
            approverName: '当前用户', // 替换为实际用户名
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已拒绝发言申请')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拒绝发言申请失败: ${e.toString()}')));
      }
    }
  }

  // 开始发言
  Future<void> _startSpeech(String requestId) async {
    try {
      await ref
          .read(speechRequestManagerProvider(requestId).notifier)
          .startSpeech(widget.meetingId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('发言已开始')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('开始发言失败: ${e.toString()}')));
      }
    }
  }

  // 结束发言
  Future<void> _endSpeech(String requestId) async {
    try {
      await ref
          .read(speechRequestManagerProvider(requestId).notifier)
          .endSpeech(widget.meetingId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('发言已结束')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('结束发言失败: ${e.toString()}')));
      }
    }
  }
}
