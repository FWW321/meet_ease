import '../models/speech_request.dart';

/// 发言申请服务接口
abstract class SpeechRequestService {
  /// 获取会议中的所有发言申请
  Future<List<SpeechRequest>> getMeetingSpeechRequests(String meetingId);

  /// 创建发言申请
  Future<SpeechRequest> createSpeechRequest(SpeechRequest request);

  /// 更新发言申请状态
  Future<SpeechRequest> updateSpeechRequestStatus(
    String requestId,
    SpeechRequestStatus status, {
    String? approverId,
    String? approverName,
  });

  /// 开始发言
  Future<SpeechRequest> startSpeech(String requestId);

  /// 结束发言
  Future<SpeechRequest> endSpeech(String requestId);

  /// 获取当前正在发言的申请
  Future<SpeechRequest?> getCurrentSpeech(String meetingId);
}

/// 模拟发言申请服务实现
class MockSpeechRequestService implements SpeechRequestService {
  // 模拟数据 - 发言申请
  final List<SpeechRequest> _speechRequests = [
    SpeechRequest(
      id: '101',
      meetingId: '1',
      requesterId: 'user1',
      requesterName: '张三',
      topic: '项目进度汇报',
      reason: '向团队汇报上周项目进展',
      estimatedDuration: const Duration(minutes: 5),
      status: SpeechRequestStatus.approved,
      requestTime: DateTime.now().subtract(const Duration(minutes: 30)),
      approvalTime: DateTime.now().subtract(const Duration(minutes: 25)),
      approverId: 'user5',
      approverName: '王组长',
      startTime: DateTime.now().subtract(const Duration(minutes: 20)),
      endTime: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    SpeechRequest(
      id: '102',
      meetingId: '1',
      requesterId: 'user2',
      requesterName: '李四',
      topic: '技术方案讨论',
      reason: '讨论新特性的技术实现方案',
      estimatedDuration: const Duration(minutes: 8),
      status: SpeechRequestStatus.approved,
      requestTime: DateTime.now().subtract(const Duration(minutes: 20)),
      approvalTime: DateTime.now().subtract(const Duration(minutes: 18)),
      approverId: 'user5',
      approverName: '王组长',
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    SpeechRequest(
      id: '103',
      meetingId: '1',
      requesterId: 'user3',
      requesterName: '王五',
      topic: '需求变更说明',
      reason: '解释最近的需求变更原因',
      estimatedDuration: const Duration(minutes: 5),
      status: SpeechRequestStatus.pending,
      requestTime: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  Future<List<SpeechRequest>> getMeetingSpeechRequests(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _speechRequests
        .where((request) => request.meetingId == meetingId)
        .toList();
  }

  @override
  Future<SpeechRequest> createSpeechRequest(SpeechRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newRequest = SpeechRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meetingId: request.meetingId,
      requesterId: request.requesterId,
      requesterName: request.requesterName,
      topic: request.topic,
      reason: request.reason,
      estimatedDuration: request.estimatedDuration,
      status: SpeechRequestStatus.pending,
      requestTime: DateTime.now(),
    );

    _speechRequests.add(newRequest);
    return newRequest;
  }

  @override
  Future<SpeechRequest> updateSpeechRequestStatus(
    String requestId,
    SpeechRequestStatus status, {
    String? approverId,
    String? approverName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _speechRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('发言申请不存在');
    }

    final request = _speechRequests[index];
    final updatedRequest = request.copyWith(
      status: status,
      approvalTime:
          status == SpeechRequestStatus.approved ||
                  status == SpeechRequestStatus.rejected
              ? DateTime.now()
              : request.approvalTime,
      approverId: approverId ?? request.approverId,
      approverName: approverName ?? request.approverName,
    );

    _speechRequests[index] = updatedRequest;
    return updatedRequest;
  }

  @override
  Future<SpeechRequest> startSpeech(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _speechRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('发言申请不存在');
    }

    final request = _speechRequests[index];
    if (request.status != SpeechRequestStatus.approved) {
      throw Exception('只有已批准的发言申请才能开始');
    }

    final updatedRequest = request.copyWith(startTime: DateTime.now());

    _speechRequests[index] = updatedRequest;
    return updatedRequest;
  }

  @override
  Future<SpeechRequest> endSpeech(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _speechRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('发言申请不存在');
    }

    final request = _speechRequests[index];
    if (request.startTime == null) {
      throw Exception('发言尚未开始');
    }

    final updatedRequest = request.copyWith(
      status: SpeechRequestStatus.completed,
      endTime: DateTime.now(),
    );

    _speechRequests[index] = updatedRequest;
    return updatedRequest;
  }

  @override
  Future<SpeechRequest?> getCurrentSpeech(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找正在进行的发言（已开始但未结束）
    try {
      return _speechRequests.firstWhere(
        (r) =>
            r.meetingId == meetingId &&
            r.status == SpeechRequestStatus.approved &&
            r.startTime != null &&
            r.endTime == null,
      );
    } catch (e) {
      // 没有正在进行的发言
      return null;
    }
  }
}
