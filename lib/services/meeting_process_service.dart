import '../models/meeting_agenda.dart';
import '../models/meeting_material.dart';
import '../models/meeting_note.dart';
import '../models/meeting_vote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../constants/app_constants.dart';
import '../services/meeting_service.dart';
import 'package:http/http.dart' as http;
import '../utils/http_utils.dart';

/// 会议过程管理服务接口
abstract class MeetingProcessService {
  /// 议程管理
  Future<MeetingAgenda> getMeetingAgenda(String meetingId);
  Future<AgendaItem> updateAgendaItemStatus(
    String meetingId,
    String itemId,
    AgendaItemStatus status,
  );

  /// 资料管理
  Future<MeetingMaterials> getMeetingMaterials(String meetingId);
  Future<MaterialItem> addMeetingMaterial(
    String meetingId,
    MaterialItem material,
  );
  Future<bool> removeMeetingMaterial(String meetingId, String materialId);

  /// 笔记管理
  Future<List<MeetingNote>> getMeetingNotes(String meetingId);
  Future<MeetingNote> addMeetingNote(MeetingNote note);
  Future<MeetingNote> updateMeetingNote(MeetingNote note);
  Future<bool> removeMeetingNote(String noteId);
  Future<bool> shareMeetingNote(String noteId, bool isShared);

  /// 投票管理
  Future<List<MeetingVote>> getMeetingVotes(String meetingId);
  Future<MeetingVote> createVote(MeetingVote vote);
  Future<MeetingVote> startVote(String voteId);
  Future<MeetingVote> closeVote(String voteId);
  Future<MeetingVote> vote(
    String voteId,
    String userId,
    List<String> optionIds,
  );
  Future<List<VoteOption>> getVoteResults(String voteId);
}

/// 模拟会议过程管理服务实现
class MockMeetingProcessService implements MeetingProcessService {
  // 模拟数据 - 会议议程
  final Map<String, MeetingAgenda> _agendas = {
    '1': MeetingAgenda(
      meetingId: '1',
      items: [
        AgendaItem(
          id: '101',
          title: '项目进度回顾',
          description: '回顾上周项目进度，分析延期原因',
          duration: const Duration(minutes: 15),
          status: AgendaItemStatus.completed,
          speakerName: '张三',
          startTime: DateTime.now().subtract(const Duration(minutes: 30)),
          endTime: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        AgendaItem(
          id: '102',
          title: '本周任务分配',
          description: '分配本周开发任务和里程碑设置',
          duration: const Duration(minutes: 20),
          status: AgendaItemStatus.inProgress,
          speakerName: '李四',
          startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        AgendaItem(
          id: '103',
          title: '技术难点讨论',
          description: '讨论当前遇到的技术难点和解决方案',
          duration: const Duration(minutes: 30),
          status: AgendaItemStatus.pending,
          speakerName: '王五',
        ),
        AgendaItem(
          id: '104',
          title: '下阶段计划',
          description: '制定下一阶段开发计划',
          duration: const Duration(minutes: 15),
          status: AgendaItemStatus.pending,
          speakerName: '赵六',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  };

  // 模拟数据 - 会议资料
  final Map<String, MeetingMaterials> _materials = {
    '1': MeetingMaterials(
      meetingId: '1',
      items: [
        MaterialItem(
          id: '201',
          title: '项目进度报告.pdf',
          description: '详细的项目进度统计报告',
          type: MaterialType.document,
          url: 'https://example.com/materials/project_report.pdf',
          fileSize: 2 * 1024 * 1024, // 2MB
          uploaderId: 'user1',
          uploaderName: '张三',
          uploadTime: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        MaterialItem(
          id: '202',
          title: '系统架构图.png',
          type: MaterialType.image,
          url: 'https://example.com/materials/architecture.png',
          thumbnailUrl: 'https://example.com/thumbnails/architecture.png',
          fileSize: 500 * 1024, // 500KB
          uploaderId: 'user2',
          uploaderName: '李四',
          uploadTime: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        MaterialItem(
          id: '203',
          title: '产品演示视频.mp4',
          description: '最新版本功能演示',
          type: MaterialType.video,
          url: 'https://example.com/materials/demo.mp4',
          thumbnailUrl: 'https://example.com/thumbnails/demo.jpg',
          fileSize: 15 * 1024 * 1024, // 15MB
          uploaderId: 'user3',
          uploaderName: '王五',
          uploadTime: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  };

  // 模拟数据 - 会议笔记
  final List<MeetingNote> _notes = [
    MeetingNote(
      id: '301',
      meetingId: '1',
      content:
          '今天讨论了项目进度问题，主要延期原因是API接口变更导致的重构工作。'
          '团队决定在本周四前完成所有重构工作，下周开始新功能开发。'
          '\n\n负责人安排：'
          '\n- 前端重构：张三'
          '\n- 后端接口适配：李四'
          '\n- 测试用例更新：王五',
      creatorId: 'user1',
      creatorName: '张三',
      isShared: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      tags: ['进度', '重构', '任务分配'],
    ),
    MeetingNote(
      id: '302',
      meetingId: '1',
      content:
          '技术难点讨论：'
          '\n1. 数据同步问题 - 决定采用乐观锁方案'
          '\n2. 性能优化 - 需要对列表页进行虚拟滚动优化'
          '\n3. 离线支持 - 调研PWA方案的可行性',
      creatorId: 'user2',
      creatorName: '李四',
      isShared: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      tags: ['技术难点', '解决方案'],
    ),
  ];

  // 模拟数据 - 会议投票
  final List<MeetingVote> _votes = [
    MeetingVote(
      id: '401',
      meetingId: '1',
      title: '下一个迭代周期优先级',
      description: '请选择您认为下一个迭代周期应该优先实现的功能',
      type: VoteType.singleChoice,
      status: VoteStatus.active,
      options: [
        VoteOption(
          id: '4011',
          text: '用户管理模块重构',
          votesCount: 3,
          voterIds: ['user1', 'user3', 'user5'],
        ),
        VoteOption(
          id: '4012',
          text: '数据分析大屏开发',
          votesCount: 2,
          voterIds: ['user2', 'user7'],
        ),
        VoteOption(
          id: '4013',
          text: '移动端适配优化',
          votesCount: 1,
          voterIds: ['user4'],
        ),
        VoteOption(
          id: '4014',
          text: 'API接口重构',
          votesCount: 2,
          voterIds: ['user6', 'user8'],
        ),
      ],
      totalVotes: 8,
      creatorId: 'user1',
      creatorName: '张三',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    MeetingVote(
      id: '402',
      meetingId: '1',
      title: '技术栈调整提案',
      description: '针对前端框架升级的提案投票',
      type: VoteType.multipleChoice,
      status: VoteStatus.pending,
      isAnonymous: true,
      options: [
        VoteOption(id: '4021', text: '升级到Vue 3'),
        VoteOption(id: '4022', text: '引入TypeScript'),
        VoteOption(id: '4023', text: '采用Vite构建工具'),
        VoteOption(id: '4024', text: '集成TailwindCSS'),
      ],
      totalVotes: 0,
      creatorId: 'user2',
      creatorName: '李四',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  // 议程管理实现
  @override
  Future<MeetingAgenda> getMeetingAgenda(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_agendas.containsKey(meetingId)) {
      return _agendas[meetingId]!;
    } else {
      // 返回空议程
      return MeetingAgenda(
        meetingId: meetingId,
        items: [],
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<AgendaItem> updateAgendaItemStatus(
    String meetingId,
    String itemId,
    AgendaItemStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!_agendas.containsKey(meetingId)) {
      throw Exception('会议议程不存在');
    }

    final agenda = _agendas[meetingId]!;
    final itemIndex = agenda.items.indexWhere((item) => item.id == itemId);

    if (itemIndex == -1) {
      throw Exception('议程项不存在');
    }

    // 更新状态
    final item = agenda.items[itemIndex];
    final updatedItem = item.copyWith(
      status: status,
      startTime:
          status == AgendaItemStatus.inProgress && item.startTime == null
              ? DateTime.now()
              : item.startTime,
      endTime:
          (status == AgendaItemStatus.completed ||
                      status == AgendaItemStatus.skipped) &&
                  item.endTime == null
              ? DateTime.now()
              : item.endTime,
    );

    // 更新议程
    final updatedItems = List<AgendaItem>.from(agenda.items);
    updatedItems[itemIndex] = updatedItem;
    _agendas[meetingId] = agenda.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    return updatedItem;
  }

  // 资料管理实现
  @override
  Future<MeetingMaterials> getMeetingMaterials(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_materials.containsKey(meetingId)) {
      return _materials[meetingId]!;
    } else {
      // 返回空资料集合
      return MeetingMaterials(
        meetingId: meetingId,
        items: [],
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<MaterialItem> addMeetingMaterial(
    String meetingId,
    MaterialItem material,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!_materials.containsKey(meetingId)) {
      // 创建新资料集合
      _materials[meetingId] = MeetingMaterials(
        meetingId: meetingId,
        items: [],
        createdAt: DateTime.now(),
      );
    }

    // 获取当前资料集合
    final materials = _materials[meetingId]!;

    // 添加新资料
    final updatedItems = List<MaterialItem>.from(materials.items)
      ..add(material);
    _materials[meetingId] = materials.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    return material;
  }

  @override
  Future<bool> removeMeetingMaterial(
    String meetingId,
    String materialId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_materials.containsKey(meetingId)) {
      return false;
    }

    // 获取当前资料集合
    final materials = _materials[meetingId]!;

    // 检查资料是否存在
    final materialIndex = materials.items.indexWhere(
      (item) => item.id == materialId,
    );
    if (materialIndex == -1) {
      return false;
    }

    // 移除资料
    final updatedItems = List<MaterialItem>.from(materials.items)
      ..removeAt(materialIndex);
    _materials[meetingId] = materials.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    return true;
  }

  // 笔记管理实现
  @override
  Future<List<MeetingNote>> getMeetingNotes(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 过滤获取指定会议的笔记
    return _notes.where((note) => note.meetingId == meetingId).toList();
  }

  @override
  Future<MeetingNote> addMeetingNote(MeetingNote note) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // 添加笔记
    _notes.add(note);
    return note;
  }

  @override
  Future<MeetingNote> updateMeetingNote(MeetingNote note) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 查找笔记
    final noteIndex = _notes.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) {
      throw Exception('笔记不存在');
    }

    // 更新笔记
    _notes[noteIndex] = note.copyWith(updatedAt: DateTime.now());
    return _notes[noteIndex];
  }

  @override
  Future<bool> removeMeetingNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找笔记
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      return false;
    }

    // 移除笔记
    _notes.removeAt(noteIndex);
    return true;
  }

  @override
  Future<bool> shareMeetingNote(String noteId, bool isShared) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找笔记
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      return false;
    }

    // 更新分享状态
    _notes[noteIndex] = _notes[noteIndex].copyWith(
      isShared: isShared,
      updatedAt: DateTime.now(),
    );
    return true;
  }

  // 投票管理实现
  @override
  Future<List<MeetingVote>> getMeetingVotes(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 过滤获取指定会议的投票
    return _votes.where((vote) => vote.meetingId == meetingId).toList();
  }

  @override
  Future<MeetingVote> createVote(MeetingVote vote) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // 添加投票
    _votes.add(vote);
    return vote;
  }

  @override
  Future<MeetingVote> startVote(String voteId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 查找投票
    final voteIndex = _votes.indexWhere((v) => v.id == voteId);
    if (voteIndex == -1) {
      throw Exception('投票不存在');
    }

    // 检查投票状态
    if (_votes[voteIndex].status != VoteStatus.pending) {
      throw Exception('只有待开始的投票才能启动');
    }

    // 更新投票状态
    _votes[voteIndex] = _votes[voteIndex].copyWith(
      status: VoteStatus.active,
      startTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _votes[voteIndex];
  }

  @override
  Future<MeetingVote> closeVote(String voteId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 查找投票
    final voteIndex = _votes.indexWhere((v) => v.id == voteId);
    if (voteIndex == -1) {
      throw Exception('投票不存在');
    }

    // 检查投票状态
    if (_votes[voteIndex].status != VoteStatus.active) {
      throw Exception('只有进行中的投票才能结束');
    }

    // 更新投票状态
    _votes[voteIndex] = _votes[voteIndex].copyWith(
      status: VoteStatus.closed,
      endTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _votes[voteIndex];
  }

  @override
  Future<MeetingVote> vote(
    String voteId,
    String userId,
    List<String> optionIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // 查找投票
    final voteIndex = _votes.indexWhere((v) => v.id == voteId);
    if (voteIndex == -1) {
      throw Exception('投票不存在');
    }

    final vote = _votes[voteIndex];

    // 检查投票状态
    if (vote.status != VoteStatus.active) {
      throw Exception('只有进行中的投票才能投票');
    }

    // 检查选项是否存在
    for (final optionId in optionIds) {
      if (!vote.options.any((option) => option.id == optionId)) {
        throw Exception('选项不存在: $optionId');
      }
    }

    // 单选时检查选项数量
    if (vote.type == VoteType.singleChoice && optionIds.length > 1) {
      throw Exception('单选投票只能选择一个选项');
    }

    // 检查用户是否已投票 (非匿名投票)
    if (!vote.isAnonymous) {
      for (final option in vote.options) {
        if (option.voterIds?.contains(userId) ?? false) {
          throw Exception('您已经投过票了');
        }
      }
    }

    // 更新投票选项
    final updatedOptions = <VoteOption>[];
    for (final option in vote.options) {
      if (optionIds.contains(option.id)) {
        // 更新选中的选项
        List<String> updatedVoterIds;
        if (option.voterIds != null) {
          updatedVoterIds = List<String>.from(option.voterIds!);
          updatedVoterIds.add(userId);
        } else {
          updatedVoterIds = <String>[userId];
        }

        updatedOptions.add(
          option.copyWith(
            votesCount: option.votesCount + 1,
            voterIds: updatedVoterIds,
          ),
        );
      } else {
        updatedOptions.add(option);
      }
    }

    // 更新投票
    _votes[voteIndex] = vote.copyWith(
      options: updatedOptions,
      totalVotes: vote.totalVotes + 1,
      updatedAt: DateTime.now(),
    );
    return _votes[voteIndex];
  }

  @override
  Future<List<VoteOption>> getVoteResults(String voteId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找投票
    final vote = _votes.firstWhere(
      (v) => v.id == voteId,
      orElse: () => throw Exception('投票不存在'),
    );

    // 返回投票结果
    return vote.options;
  }
}

/// API会议过程管理服务实现 - 将来用于实际的后端API调用
class ApiMeetingProcessService implements MeetingProcessService {
  // 会议服务实例
  final MeetingService _meetingService;

  // 构造函数
  ApiMeetingProcessService(this._meetingService);

  @override
  Future<MeetingAgenda> getMeetingAgenda(String meetingId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<AgendaItem> updateAgendaItemStatus(
    String meetingId,
    String itemId,
    AgendaItemStatus status,
  ) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingMaterials> getMeetingMaterials(String meetingId) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 请求会议文件列表
      final response = await client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/file/list/$meetingId'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final fileList = responseData['data'] as List<dynamic>;

          // 将API响应数据转换为MaterialItem列表
          final materialItems =
              fileList.map<MaterialItem>((file) {
                // 根据文件类型确定MaterialType
                MaterialType fileType = MaterialType.other;
                final String fileExt =
                    file['fileType'].toString().toLowerCase();

                if ([
                  '.pdf',
                  '.doc',
                  '.docx',
                  '.txt',
                  '.xls',
                  '.xlsx',
                ].contains(fileExt)) {
                  fileType = MaterialType.document;
                } else if ([
                  '.jpg',
                  '.jpeg',
                  '.png',
                  '.gif',
                  '.webp',
                ].contains(fileExt)) {
                  fileType = MaterialType.image;
                } else if ([
                  '.mp4',
                  '.mov',
                  '.avi',
                  '.mkv',
                  '.webm',
                ].contains(fileExt)) {
                  fileType = MaterialType.video;
                } else if (['.ppt', '.pptx', '.key'].contains(fileExt)) {
                  fileType = MaterialType.presentation;
                }

                // 构建文件URL
                final String filePath = file['filePath'];
                final String fileId = file['fileId'].toString();
                final String fileUrl =
                    '${AppConstants.apiBaseUrl}/meeting/file/download/$meetingId/$fileId';

                // 构建缩略图URL（如果是图片或视频类型）
                String? thumbnailUrl;
                if (fileType == MaterialType.image ||
                    fileType == MaterialType.video) {
                  thumbnailUrl = fileUrl;
                }

                // 解析上传时间
                DateTime? uploadTime;
                if (file['uploadTime'] != null) {
                  try {
                    uploadTime = DateTime.parse(file['uploadTime']);
                  } catch (e) {
                    // 忽略解析错误
                  }
                }

                return MaterialItem(
                  id: file['fileId'].toString(),
                  title: file['fileName'],
                  description: null, // API没有提供文件描述
                  type: fileType,
                  url: fileUrl,
                  thumbnailUrl: thumbnailUrl,
                  fileSize: file['fileSize'],
                  uploaderId: file['uploaderId']?.toString(),
                  uploaderName: null, // API没有提供上传者姓名
                  uploadTime: uploadTime,
                );
              }).toList();

          // 返回会议资料集合
          return MeetingMaterials(
            meetingId: meetingId,
            items: materialItems,
            updatedAt: DateTime.now(),
          );
        } else {
          final message = responseData['message'] ?? '获取会议资料失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '获取会议资料请求失败'),
        );
      }
    } catch (e) {
      throw Exception('获取会议资料时出错: $e');
    }
  }

  @override
  Future<MaterialItem> addMeetingMaterial(
    String meetingId,
    MaterialItem material,
  ) async {
    try {
      // 如果material.url是本地文件路径，则需要上传文件
      if (material.url.startsWith('file://') ||
          !material.url.startsWith('http')) {
        // 获取当前用户ID
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        String uploaderId = '';

        if (userJson != null) {
          final userData = jsonDecode(userJson);
          uploaderId = userData['id'] ?? '';
        }

        // 上传文件
        final fileToUpload = File(material.url);
        final success = await _meetingService.uploadMeetingFile(
          meetingId,
          uploaderId,
          fileToUpload,
        );

        if (!success) {
          throw Exception('上传文件失败');
        }

        // TODO: 获取服务器返回的实际URL和其他信息
        // 这里暂时模拟返回一个成功的结果
        return material.copyWith(
          id: 'server_generated_id_${DateTime.now().millisecondsSinceEpoch}',
          url:
              'https://example.com/uploaded_files/${fileToUpload.path.split('/').last}',
        );
      }

      // 如果URL已经是远程URL，直接返回material
      return material;
    } catch (e) {
      throw Exception('添加会议资料时出错: $e');
    }
  }

  @override
  Future<bool> removeMeetingMaterial(
    String meetingId,
    String materialId,
  ) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<List<MeetingNote>> getMeetingNotes(String meetingId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingNote> addMeetingNote(MeetingNote note) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingNote> updateMeetingNote(MeetingNote note) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<bool> removeMeetingNote(String noteId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<bool> shareMeetingNote(String noteId, bool isShared) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<List<MeetingVote>> getMeetingVotes(String meetingId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingVote> createVote(MeetingVote vote) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingVote> startVote(String voteId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingVote> closeVote(String voteId) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<MeetingVote> vote(
    String voteId,
    String userId,
    List<String> optionIds,
  ) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<List<VoteOption>> getVoteResults(String voteId) async {
    throw UnimplementedError('API服务尚未实现');
  }
}
