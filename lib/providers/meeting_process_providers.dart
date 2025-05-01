import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/meeting_agenda.dart';
import '../models/meeting_material.dart';
import '../models/meeting_note.dart';
import '../models/meeting_vote.dart';
import '../services/meeting_process_service.dart';
import '../services/meeting_service.dart';

part 'meeting_process_providers.g.dart';

/// 会议过程管理服务提供者
final meetingProcessServiceProvider = Provider<MeetingProcessService>((ref) {
  // 获取会议服务实例
  final meetingService = ref.watch(meetingServiceProvider);

  // 根据环境配置决定使用模拟服务还是API服务
  final bool useApiService = const bool.fromEnvironment(
    'USE_API_SERVICE',
    defaultValue: true,
  );

  if (useApiService) {
    return ApiMeetingProcessService(meetingService);
  } else {
    return MockMeetingProcessService();
  }
});

/// 会议服务提供者
final meetingServiceProvider = Provider<MeetingService>((ref) {
  // 使用真实API服务
  return ApiMeetingService();
});

///--------------------- 会议议程相关 ---------------------///

/// 会议议程提供者
@riverpod
Future<MeetingAgenda> meetingAgenda(Ref ref, String meetingId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  return service.getMeetingAgenda(meetingId);
}

/// 议程项状态更新提供者
@riverpod
class AgendaItemStatusNotifier extends _$AgendaItemStatusNotifier {
  @override
  Future<AgendaItem?> build(String agendaItemId, String meetingId) async {
    // 查找议程项
    final agenda = await ref.watch(meetingAgendaProvider(meetingId).future);
    return agenda.items.firstWhere(
      (item) => item.id == agendaItemId,
      orElse: () => throw Exception('议程项不存在'),
    );
  }

  // 更新议程项状态
  Future<void> updateStatus(AgendaItemStatus status) async {
    if (state.value == null) return;

    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final updatedItem = await service.updateAgendaItemStatus(
        meetingId,
        agendaItemId,
        status,
      );

      // 更新状态
      state = AsyncValue.data(updatedItem);

      // 刷新议程
      ref.invalidate(meetingAgendaProvider(meetingId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

///--------------------- 会议资料相关 ---------------------///

/// 会议资料提供者
@riverpod
Future<MeetingMaterials> meetingMaterials(Ref ref, String meetingId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  return service.getMeetingMaterials(meetingId);
}

/// 会议资料管理提供者
@riverpod
class MeetingMaterialsNotifier extends _$MeetingMaterialsNotifier {
  @override
  Future<MeetingMaterials> build(String meetingId) async {
    final service = ref.watch(meetingProcessServiceProvider);
    return service.getMeetingMaterials(meetingId);
  }

  // 添加资料
  Future<void> addMaterial(MaterialItem material) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      await service.addMeetingMaterial(meetingId, material);

      // 刷新资料列表
      final updatedMaterials = await service.getMeetingMaterials(meetingId);
      state = AsyncValue.data(updatedMaterials);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 删除资料
  Future<void> removeMaterial(String materialId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final success = await service.removeMeetingMaterial(
        meetingId,
        materialId,
      );

      if (success) {
        // 刷新资料列表
        final updatedMaterials = await service.getMeetingMaterials(meetingId);
        state = AsyncValue.data(updatedMaterials);
      } else {
        state = AsyncValue.error('删除资料失败', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

///--------------------- 会议笔记相关 ---------------------///

/// 会议笔记提供者
@riverpod
Future<List<MeetingNote>> meetingNotes(Ref ref, String meetingId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  return service.getMeetingNotes(meetingId);
}

/// 会议笔记管理提供者
@riverpod
class MeetingNotesNotifier extends _$MeetingNotesNotifier {
  @override
  Future<List<MeetingNote>> build(String meetingId) async {
    final service = ref.watch(meetingProcessServiceProvider);
    return service.getMeetingNotes(meetingId);
  }

  // 添加笔记
  Future<void> addNote(MeetingNote note) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      await service.addMeetingNote(note);

      // 刷新笔记列表
      final updatedNotes = await service.getMeetingNotes(meetingId);
      state = AsyncValue.data(updatedNotes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 刷新笔记列表
  Future<void> refreshNotes() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final updatedNotes = await service.getMeetingNotes(meetingId);
      state = AsyncValue.data(updatedNotes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 更新笔记
  Future<void> updateNote(MeetingNote note) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      await service.updateMeetingNote(note);

      // 刷新笔记列表
      final updatedNotes = await service.getMeetingNotes(meetingId);
      state = AsyncValue.data(updatedNotes);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 删除笔记
  Future<void> removeNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final success = await service.removeMeetingNote(noteId);

      if (success) {
        // 刷新笔记列表
        final updatedNotes = await service.getMeetingNotes(meetingId);
        state = AsyncValue.data(updatedNotes);
      } else {
        state = AsyncValue.error('删除笔记失败', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 分享笔记
  Future<void> shareNote(String noteId, bool isShared) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final success = await service.shareMeetingNote(noteId, isShared);

      if (success) {
        // 刷新笔记列表
        final updatedNotes = await service.getMeetingNotes(meetingId);
        state = AsyncValue.data(updatedNotes);
      } else {
        state = AsyncValue.error('更新笔记分享状态失败', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

///--------------------- 会议投票相关 ---------------------///

/// 会议投票列表提供者
@riverpod
Future<List<MeetingVote>> meetingVotes(Ref ref, String meetingId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  return service.getMeetingVotes(meetingId);
}

/// 单个投票详情提供者
@riverpod
Future<MeetingVote> voteDetail(Ref ref, String voteId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  final votes = await service.getMeetingVotes(''); // 此处简化处理，实际应从投票ID推导会议ID
  return votes.firstWhere(
    (vote) => vote.id == voteId,
    orElse: () => throw Exception('投票不存在'),
  );
}

/// 投票结果提供者
@riverpod
Future<List<VoteOption>> voteResults(Ref ref, String voteId) async {
  final service = ref.watch(meetingProcessServiceProvider);
  return service.getVoteResults(voteId);
}

/// 投票管理提供者
@riverpod
class VoteNotifier extends _$VoteNotifier {
  @override
  Future<MeetingVote?> build(String voteId, {String? meetingId}) async {
    if (voteId.isEmpty) return null;

    final service = ref.watch(meetingProcessServiceProvider);
    final votes = await service.getMeetingVotes(meetingId ?? '');
    return votes.firstWhere(
      (vote) => vote.id == voteId,
      orElse: () => throw Exception('投票不存在'),
    );
  }

  // 创建新投票
  Future<void> createNewVote(MeetingVote vote) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final createdVote = await service.createVote(vote);

      // 更新状态
      state = AsyncValue.data(createdVote);

      // 刷新投票列表
      if (vote.meetingId.isNotEmpty) {
        ref.invalidate(meetingVotesProvider(vote.meetingId));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 开始投票
  Future<void> startVote() async {
    if (state.value == null) return;

    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final updatedVote = await service.startVote(voteId);

      // 更新状态
      state = AsyncValue.data(updatedVote);

      // 刷新相关提供者
      if (meetingId != null) {
        ref.invalidate(meetingVotesProvider(meetingId!));
      }
      ref.invalidate(voteResultsProvider(voteId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 结束投票
  Future<void> closeVote() async {
    if (state.value == null) return;

    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final updatedVote = await service.closeVote(voteId);

      // 更新状态
      state = AsyncValue.data(updatedVote);

      // 刷新相关提供者
      if (meetingId != null) {
        ref.invalidate(meetingVotesProvider(meetingId!));
      }
      ref.invalidate(voteResultsProvider(voteId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 投票
  Future<void> submitVote(String userId, List<String> optionIds) async {
    if (state.value == null) return;

    state = const AsyncValue.loading();
    try {
      final service = ref.read(meetingProcessServiceProvider);
      final updatedVote = await service.vote(voteId, userId, optionIds);

      // 更新状态
      state = AsyncValue.data(updatedVote);

      // 刷新投票结果
      ref.invalidate(voteResultsProvider(voteId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
