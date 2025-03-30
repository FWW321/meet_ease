// ignore_for_file: invalid_annotation_target, unused_element
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/speech_request.dart';
import '../services/service_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 由于使用了 riverpod 代码生成，需要生成 g.dart 文件
// 运行 flutter pub run build_runner build --delete-conflicting-outputs
part 'speech_request_providers.g.dart';

/// 会议发言申请列表提供者
@riverpod
Future<List<SpeechRequest>> meetingSpeechRequests(
  Ref ref,
  String meetingId,
) async {
  final service = ref.watch(speechRequestServiceProvider);
  return service.getMeetingSpeechRequests(meetingId);
}

/// 当前正在进行的发言提供者
@riverpod
Future<SpeechRequest?> currentSpeech(
  Ref ref,
  String meetingId,
) async {
  final service = ref.watch(speechRequestServiceProvider);
  return service.getCurrentSpeech(meetingId);
}

/// 创建发言申请提供者
@riverpod
class SpeechRequestCreator extends _$SpeechRequestCreator {
  @override
  Future<SpeechRequest?> build() {
    return Future.value(null);
  }

  Future<SpeechRequest> createSpeechRequest({
    required String meetingId,
    required String requesterId,
    required String requesterName,
    required String topic,
    String? reason,
    required Duration estimatedDuration,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(speechRequestServiceProvider);
      final request = SpeechRequest(
        id: '',
        meetingId: meetingId,
        requesterId: requesterId,
        requesterName: requesterName,
        topic: topic,
        reason: reason,
        estimatedDuration: estimatedDuration,
        status: SpeechRequestStatus.pending,
        requestTime: DateTime.now(),
      );

      final createdRequest = await service.createSpeechRequest(request);
      state = AsyncValue.data(createdRequest);

      // 刷新会议发言申请列表
      ref.invalidate(meetingSpeechRequestsProvider(meetingId));

      return createdRequest;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// 管理发言申请提供者
@riverpod
class SpeechRequestManager extends _$SpeechRequestManager {
  @override
  Future<SpeechRequest?> build(String requestId) {
    return Future.value(null);
  }

  Future<SpeechRequest> approve({
    required String meetingId,
    required String approverId,
    required String approverName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(speechRequestServiceProvider);
      final updatedRequest = await service.updateSpeechRequestStatus(
        requestId,
        SpeechRequestStatus.approved,
        approverId: approverId,
        approverName: approverName,
      );

      state = AsyncValue.data(updatedRequest);

      // 刷新会议发言申请列表
      ref.invalidate(meetingSpeechRequestsProvider(meetingId));

      return updatedRequest;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<SpeechRequest> reject({
    required String meetingId,
    required String approverId,
    required String approverName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(speechRequestServiceProvider);
      final updatedRequest = await service.updateSpeechRequestStatus(
        requestId,
        SpeechRequestStatus.rejected,
        approverId: approverId,
        approverName: approverName,
      );

      state = AsyncValue.data(updatedRequest);

      // 刷新会议发言申请列表
      ref.invalidate(meetingSpeechRequestsProvider(meetingId));

      return updatedRequest;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<SpeechRequest> startSpeech(String meetingId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(speechRequestServiceProvider);
      final updatedRequest = await service.startSpeech(requestId);

      state = AsyncValue.data(updatedRequest);

      // 刷新会议发言申请列表和当前发言
      ref.invalidate(meetingSpeechRequestsProvider(meetingId));
      ref.invalidate(currentSpeechProvider(meetingId));

      return updatedRequest;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<SpeechRequest> endSpeech(String meetingId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(speechRequestServiceProvider);
      final updatedRequest = await service.endSpeech(requestId);

      state = AsyncValue.data(updatedRequest);

      // 刷新会议发言申请列表和当前发言
      ref.invalidate(meetingSpeechRequestsProvider(meetingId));
      ref.invalidate(currentSpeechProvider(meetingId));

      return updatedRequest;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
