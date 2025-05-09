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
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../services/api_user_service.dart';

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
  Future<List<MeetingNote>> getMeetingNotes(String meetingId, {String? userId});
  Future<MeetingNote?> getNoteDetail(String noteId);
  Future<MeetingNote> addMeetingNote(MeetingNote note);
  Future<MeetingNote> updateMeetingNote(MeetingNote note);
  Future<bool> removeMeetingNote(String noteId, {String? userId});
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
  Future<List<MeetingNote>> getMeetingNotes(
    String meetingId, {
    String? userId,
  }) async {
    // 返回模拟数据
    return _notes.where((note) => note.meetingId == meetingId).toList();
  }

  @override
  Future<MeetingNote?> getNoteDetail(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找笔记
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      return null;
    }

    return _notes[noteIndex];
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
  Future<bool> removeMeetingNote(String noteId, {String? userId}) async {
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
  // 用户服务实例
  final UserService _userService;

  // 构造函数
  ApiMeetingProcessService(this._meetingService, {UserService? userService})
    : _userService = userService ?? ApiUserService();

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

        // 添加调试日志
        print('获取会议资料响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200) {
          final data = responseData['data'];
          final List<dynamic> fileList;

          // 处理不同格式的响应数据
          if (data is List) {
            fileList = data;
          } else if (data is Map && data.containsKey('records')) {
            fileList = data['records'] as List<dynamic>;
          } else if (data is Map && data.containsKey('files')) {
            fileList = data['files'] as List<dynamic>;
          } else {
            // 返回空列表，避免出错
            return MeetingMaterials(
              meetingId: meetingId,
              items: [],
              updatedAt: DateTime.now(),
            );
          }

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
  Future<List<MeetingNote>> getMeetingNotes(
    String meetingId, {
    String? userId,
  }) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 如果没有传入userId，尝试从本地获取
      String? userIdParam = userId;
      if (userIdParam == null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        userIdParam = prefs.getString('userId');
      }

      // 构建API请求URL
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/notes/list/$meetingId',
      ).replace(
        queryParameters: {if (userIdParam != null) 'userId': userIdParam},
      );

      // 发送GET请求
      final response = await client.get(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final List<dynamic> notesData = responseData['data'];

          // 创建MeetingNote列表的Future
          final futureNotes = Future.wait(
            notesData.map<Future<MeetingNote>>((noteData) async {
              // 解析时间
              final DateTime createdAt = DateTime.parse(noteData['createdAt']);
              DateTime? updatedAt;
              if (noteData['updatedAt'] != null) {
                updatedAt = DateTime.parse(noteData['updatedAt']);
              }

              // 获取用户ID
              final noteUserId = noteData['userId'].toString();

              // 获取用户名称
              String creatorName;
              try {
                creatorName = await _userService.getUserNameById(noteUserId);
              } catch (e) {
                // 如果获取用户名失败，则使用备用值
                creatorName = noteData['userName'] ?? 'Unknown';
              }

              // 创建MeetingNote对象
              return MeetingNote(
                id: noteData['noteId'].toString(),
                meetingId: noteData['meetingId'].toString(),
                content: noteData['noteContent'],
                noteName: noteData['noteName'],
                creatorId: noteUserId,
                creatorName: creatorName,
                isShared:
                    noteData['isPublic'] == true || noteData['isPublic'] == 1,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: null, // API目前不支持标签
              );
            }),
          );

          // 等待所有笔记处理完成并返回
          return await futureNotes;
        }
      }

      // 如果请求失败或没有数据，返回空列表
      print('获取会议笔记列表失败: HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      print('获取会议笔记列表出错: $e');
      // 出错时返回空列表而不是抛出异常，确保UI不会崩溃
      return [];
    }
  }

  @override
  Future<MeetingNote> addMeetingNote(MeetingNote note) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 从note对象中获取必要参数
      final meetingId = note.meetingId;
      final userId = note.creatorId;
      final content = note.content;
      final isPublic = note.isShared ? '1' : '0';

      // 构建URL和请求参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/notes/create',
      ).replace(
        queryParameters: {
          'meetingId': meetingId,
          'userId': userId,
          'content': content,
          'isPublic': isPublic,
          if (note.noteName != null && note.noteName!.isNotEmpty)
            'noteName': note.noteName!,
        },
      );

      // 发送请求
      final response = await client.post(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加日志
        print('创建会议笔记响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];

          // 从响应中解析笔记信息
          final noteId = data['noteId'].toString();
          final createdAt = DateTime.parse(data['createdAt']);

          // 创建新的笔记对象
          final newNote = MeetingNote(
            id: noteId,
            meetingId: data['meetingId'].toString(),
            content: data['noteContent'],
            creatorId: data['userId'].toString(),
            creatorName: note.creatorName, // API响应中没有creatorName，使用请求中的值
            isShared: data['isPublic'] == true,
            createdAt: createdAt,
            tags: note.tags, // API暂未支持标签，使用请求中的值
          );

          // 将新笔记保存到本地存储
          await _saveNoteToLocal(newNote);

          return newNote;
        } else {
          throw Exception('创建会议笔记失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('创建会议笔记失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('创建会议笔记出错: $e');
      throw Exception('创建会议笔记时出错: $e');
    }
  }

  /// 通过上传文件添加会议笔记
  Future<MeetingNote> addMeetingNoteByFile(
    String meetingId,
    String userId,
    String creatorName,
    File file,
    bool isShared,
    List<String>? tags,
    String? noteName,
  ) async {
    try {
      // 创建MultipartRequest
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/notes/upload'),
      );

      // 添加头部
      request.headers.addAll(
        HttpUtils.createHeaders(
          additionalHeaders: {'Content-Type': 'multipart/form-data'},
        ),
      );

      // 添加表单字段
      request.fields['meetingId'] = meetingId;
      request.fields['userId'] = userId;
      request.fields['isPublic'] = isShared ? '1' : '0';

      // 添加笔记名称参数
      if (noteName != null && noteName.isNotEmpty) {
        request.fields['noteName'] = noteName;
      }

      // 添加文件
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
        ),
      );

      // 打印请求内容用于调试
      print(
        '上传笔记文件请求参数: meetingId=$meetingId, userId=$userId, isPublic=${isShared ? '1' : '0'}, 文件名=${file.path.split('/').last}, noteName=$noteName',
      );

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加日志
        print('上传笔记文件响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];

          // 从响应中解析笔记信息 - 根据提供的响应示例格式解析
          final noteId = data['noteId'].toString();
          final noteContent = data['noteContent'] as String;
          final isPublic = data['isPublic'] == true || data['isPublic'] == 1;
          final receivedNoteName = data['noteName'] as String?;
          DateTime createdAt;

          try {
            // 尝试解析创建时间
            createdAt = DateTime.parse(data['createdAt'].toString());
          } catch (e) {
            print('解析创建时间失败: $e');
            createdAt = DateTime.now();
          }

          // 创建新的笔记对象
          final newNote = MeetingNote(
            id: noteId,
            meetingId: data['meetingId'].toString(),
            content: noteContent,
            noteName: receivedNoteName, // 使用API返回的笔记名称
            creatorId: data['userId'].toString(),
            creatorName: creatorName, // API返回没有包含创建者名称
            isShared: isPublic,
            createdAt: createdAt,
            tags: tags, // API返回没有包含标签信息
          );

          // 将新笔记保存到本地存储
          await _saveNoteToLocal(newNote);

          return newNote;
        } else {
          throw Exception('上传笔记文件失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('上传笔记文件失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('上传笔记文件出错: $e');
      throw Exception('上传笔记文件时出错: $e');
    }
  }

  // 将笔记保存到本地存储
  Future<void> _saveNoteToLocal(MeetingNote note) async {
    try {
      // 获取SharedPreferences实例
      final prefs = await SharedPreferences.getInstance();

      // 构建存储键名
      final String storageKey = 'meeting_notes_${note.meetingId}';

      // 获取现有的笔记列表
      final existingNotesJson = prefs.getString(storageKey) ?? '[]';
      final List<dynamic> existingNotes = jsonDecode(existingNotesJson);

      // 检查是否已存在相同ID的笔记
      final existingNoteIndex = existingNotes.indexWhere(
        (item) => item['id'] == note.id,
      );

      // 准备要存储的笔记数据
      final noteData = {
        'id': note.id,
        'meetingId': note.meetingId,
        'content': note.content,
        'creatorId': note.creatorId,
        'creatorName': note.creatorName,
        'isShared': note.isShared,
        'createdAt': note.createdAt.toIso8601String(),
        if (note.updatedAt != null)
          'updatedAt': note.updatedAt!.toIso8601String(),
        if (note.tags != null) 'tags': note.tags,
      };

      // 更新笔记列表
      if (existingNoteIndex >= 0) {
        // 更新现有笔记
        existingNotes[existingNoteIndex] = noteData;
      } else {
        // 添加新笔记
        existingNotes.add(noteData);
      }

      // 将更新后的笔记列表保存回本地存储
      await prefs.setString(storageKey, jsonEncode(existingNotes));
    } catch (e) {
      print('保存笔记到本地存储出错: $e');
      // 继续抛出异常，让调用者处理
      rethrow;
    }
  }

  @override
  Future<MeetingNote> updateMeetingNote(MeetingNote note) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 获取必要的参数
      final noteId = note.id;
      final content = note.content;
      final noteName = note.noteName ?? '';
      final isPublic = note.isShared ? '1' : '0';

      // 构建API请求URL，添加查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/notes/$noteId',
      ).replace(
        queryParameters: {
          'userId': note.creatorId,
          'noteName': noteName,
          'content': content,
          'isPublic': isPublic,
        },
      );

      // 添加调试信息
      print('更新笔记请求URL: $uri');

      // 发送PUT请求
      final response = await client.put(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加调试日志
        print('更新笔记响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200) {
          // 更新成功，返回更新后的笔记对象
          return note.copyWith(updatedAt: DateTime.now());
        } else {
          final message = responseData['message'] ?? '更新笔记失败';
          throw Exception(message);
        }
      } else {
        throw Exception('更新笔记请求失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('更新笔记出错: $e');
      throw Exception('更新笔记时出错: $e');
    }
  }

  @override
  Future<bool> removeMeetingNote(String noteId, {String? userId}) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 获取当前用户ID
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userIdParam = userId ?? prefs.getString('userId');

      if (userIdParam == null || userIdParam.isEmpty) {
        print('删除笔记失败: 未找到用户ID');
        return false;
      }

      // 构建API请求URL，添加userId查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/notes/$noteId',
      ).replace(queryParameters: {'userId': userIdParam});

      print('删除笔记请求URL: $uri');

      // 发送DELETE请求
      final response = await client.delete(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加日志
        print('删除笔记响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200) {
          return true;
        } else {
          final errorMsg = responseData['message'] ?? '删除笔记失败';
          print('删除笔记失败: $errorMsg');
          return false;
        }
      } else {
        final errorMsg = '删除笔记请求失败: HTTP ${response.statusCode}';
        print(errorMsg);
        return false;
      }
    } catch (e) {
      print('删除笔记出错: $e');
      return false;
    }
  }

  @override
  Future<bool> shareMeetingNote(String noteId, bool isShared) async {
    throw UnimplementedError('API服务尚未实现');
  }

  @override
  Future<List<MeetingVote>> getMeetingVotes(String meetingId) async {
    try {
      // 尝试获取会议ID为数字
      final meetingIdParam = int.tryParse(meetingId) ?? meetingId;

      // 创建HTTP客户端
      final client = http.Client();

      // 发起获取投票列表请求
      final response = await client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/vote/meeting/$meetingIdParam'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加日志
        print('获取投票列表响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'] as List<dynamic>;

          // 将API响应数据转换为MeetingVote对象列表
          return data.map<MeetingVote>((voteData) {
            // 解析时间
            DateTime? startTime;
            DateTime? endTime;
            DateTime? createdAt;

            if (voteData['startTime'] != null &&
                voteData['startTime'].toString().isNotEmpty) {
              startTime = DateTime.parse(
                voteData['startTime'].toString().replaceAll(' ', 'T'),
              );
            }

            if (voteData['endTime'] != null &&
                voteData['endTime'].toString().isNotEmpty) {
              endTime = DateTime.parse(
                voteData['endTime'].toString().replaceAll(' ', 'T'),
              );
            }

            if (voteData['createdAt'] != null &&
                voteData['createdAt'].toString().isNotEmpty) {
              createdAt = DateTime.parse(voteData['createdAt'].toString());
            } else {
              createdAt = DateTime.now();
            }

            // 解析状态
            VoteStatus status = VoteStatus.pending;
            if (voteData['status'] == '进行中') {
              status = VoteStatus.active;
            } else if (voteData['status'] == '已结束') {
              status = VoteStatus.closed;
            }

            // 由于API返回的数据没有选项信息，创建一个空的选项列表
            // 真实情况会在获取投票详情时填充选项
            final voteOptions = <VoteOption>[];

            // 创建并返回投票对象
            return MeetingVote(
              id: voteData['voteId'].toString(),
              meetingId: voteData['meetingId'].toString(),
              title: voteData['title'],
              description: voteData['description'],
              type:
                  voteData['isMultiple'] == true
                      ? VoteType.multipleChoice
                      : VoteType.singleChoice,
              status: status,
              isAnonymous: voteData['isAnonymous'] == true,
              startTime: startTime,
              endTime: endTime,
              options: voteOptions,
              totalVotes: 0, // 这个信息可能需要在获取详情时更新
              creatorId: 'default',
              creatorName: '未知用户',
              createdAt: createdAt,
            );
          }).toList();
        } else {
          throw Exception('获取投票列表失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('获取投票列表失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('获取投票列表出错: $e');
      throw Exception('获取投票列表时出错: $e');
    }
  }

  @override
  Future<MeetingVote> createVote(MeetingVote vote) async {
    try {
      // 准备请求参数
      final Map<String, dynamic> requestBody = {
        'meetingId':
            int.tryParse(vote.meetingId) ?? vote.meetingId, // 尝试将字符串转换为数字
        'title': vote.title,
        'description': vote.description ?? '',
        'isMultiple': vote.type == VoteType.multipleChoice,
        'isAnonymous': vote.isAnonymous,
        'options': vote.options.map((option) => option.text).toList(),
      };

      // 如果有截止时间，添加到请求中
      if (vote.endTime != null) {
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        requestBody['endTime'] = formatter.format(vote.endTime!);
      }

      // 打印请求参数作为调试信息
      print('创建投票请求参数: ${jsonEncode(requestBody)}');

      // 创建HTTP客户端
      final client = http.Client();

      // 发起创建投票请求
      final response = await client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/vote/create'),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加日志
        print('创建投票响应: $responseData');

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];

          // 从响应中解析投票ID和状态等信息
          final voteId = data['voteId'].toString();
          final meetingId = data['meetingId'].toString();
          final startTimeStr = data['startTime'] as String?;
          final endTimeStr = data['endTime'] as String?;
          final statusStr = data['status'] as String?;

          // 解析时间
          DateTime? startTime;
          DateTime? endTime;
          if (startTimeStr != null && startTimeStr.isNotEmpty) {
            startTime = DateTime.parse(startTimeStr.replaceAll(' ', 'T'));
          }
          if (endTimeStr != null && endTimeStr.isNotEmpty) {
            endTime = DateTime.parse(endTimeStr.replaceAll(' ', 'T'));
          }

          // 解析状态
          VoteStatus status = VoteStatus.pending;
          if (statusStr == '进行中') {
            status = VoteStatus.active;
          } else if (statusStr == '已结束') {
            status = VoteStatus.closed;
          }

          // 创建并返回投票对象
          return MeetingVote(
            id: voteId,
            meetingId: meetingId,
            title: vote.title,
            description: vote.description,
            type: vote.type,
            status: status,
            isAnonymous: vote.isAnonymous,
            options: vote.options,
            startTime: startTime,
            endTime: endTime,
            totalVotes: 0,
            creatorId: vote.creatorId,
            creatorName: vote.creatorName,
            createdAt: DateTime.now(),
          );
        } else {
          throw Exception('创建投票失败: ${responseData['message']}');
        }
      } else {
        throw Exception('创建投票失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('创建投票时出错: $e');
    }
  }

  @override
  Future<MeetingVote> startVote(String voteId) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 发起开始投票请求
      final response = await client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/vote/start/$voteId'),
        headers: HttpUtils.createHeaders(),
      );

      // 添加日志
      print('开始投票响应: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 尝试获取当前投票信息
          final votes = await getMeetingVotes('');
          final currentVote = votes.firstWhere(
            (v) => v.id == voteId,
            orElse: () => throw Exception('投票不存在'),
          );

          // 返回开始状态的投票
          return currentVote.copyWith(
            status: VoteStatus.active,
            startTime: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          throw Exception('开始投票失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('开始投票失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('开始投票出错: $e');
      throw Exception('开始投票时出错: $e');
    }
  }

  @override
  Future<MeetingVote> closeVote(String voteId) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 发起结束投票请求
      final response = await client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/vote/end/$voteId'),
        headers: HttpUtils.createHeaders(),
      );

      // 添加日志
      print('结束投票响应: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 尝试获取当前投票信息
          final votes = await getMeetingVotes('');
          final currentVote = votes.firstWhere(
            (v) => v.id == voteId,
            orElse: () => throw Exception('投票不存在'),
          );

          // 返回结束状态的投票
          return currentVote.copyWith(
            status: VoteStatus.closed,
            endTime: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          throw Exception('结束投票失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('结束投票失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('结束投票出错: $e');
      throw Exception('结束投票时出错: $e');
    }
  }

  @override
  Future<MeetingVote> vote(
    String voteId,
    String userId,
    List<String> optionIds,
  ) async {
    try {
      if (optionIds.isEmpty) {
        throw Exception('未选择任何选项');
      }

      // 创建HTTP客户端
      final client = http.Client();

      // 准备请求URL，添加userId作为查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/vote/submit/$voteId',
      ).replace(queryParameters: {'userId': userId});

      // 发起提交投票请求，将选项ID列表作为JSON数组发送
      final response = await client.post(
        uri,
        headers: HttpUtils.createHeaders(),
        body: jsonEncode(optionIds),
      );

      // 添加日志
      print('提交投票响应: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 投票成功，获取更新后的投票信息
          // 因为API不返回更新后的对象，所以我们需要再次获取投票详情
          // 这里暂时返回一个模拟的对象，然后刷新界面时会获取最新数据

          // 首先尝试获取当前投票信息
          final votes = await getMeetingVotes('');
          final currentVote = votes.firstWhere(
            (v) => v.id == voteId,
            orElse: () => throw Exception('投票不存在'),
          );

          // 由于我们不知道实际结果如何，创建一个投票成功的临时对象
          return currentVote.copyWith(
            totalVotes: currentVote.totalVotes + 1,
            updatedAt: DateTime.now(),
          );
        } else {
          throw Exception('提交投票失败: ${responseData['message'] ?? "未知错误"}');
        }
      } else {
        throw Exception('提交投票失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('提交投票出错: $e');
      throw Exception('提交投票时出错: $e');
    }
  }

  @override
  Future<List<VoteOption>> getVoteResults(String voteId) async {
    try {
      print('正在获取投票选项，投票ID: $voteId');

      // 创建HTTP客户端
      final client = http.Client();

      // 构建请求URL
      final url = '${AppConstants.apiBaseUrl}/vote/detail/$voteId';
      print('请求URL: $url');

      // 发起获取投票选项请求
      final response = await client.get(
        Uri.parse(url),
        headers: HttpUtils.createHeaders(),
      );

      // 打印完整的响应内容
      print('获取投票选项响应状态码: ${response.statusCode}');
      print('获取投票选项响应头: ${response.headers}');
      print('获取投票选项响应体: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 添加详细日志
        print('解码后的响应数据: $responseData');
        print('响应码: ${responseData['code']}');
        print('响应消息: ${responseData['message']}');
        print('响应数据类型: ${responseData['data']?.runtimeType}');

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final data = responseData['data'] as List<dynamic>;
          print('投票选项数量: ${data.length}');

          // 打印每个选项的内容
          for (var i = 0; i < data.length; i++) {
            print('选项 $i: ${data[i]}');
          }

          // 将API响应数据转换为VoteOption对象列表
          final options =
              data.map<VoteOption>((optionData) {
                final id = optionData['optionId'].toString();
                final text = optionData['content'].toString();
                final votesCount = optionData['voteCount'] as int? ?? 0;

                print('转换选项: id=$id, text=$text, votesCount=$votesCount');

                return VoteOption(
                  id: id,
                  text: text,
                  votesCount: votesCount,
                  // 由于API不返回投票人信息，我们使用空列表
                  voterIds: [],
                );
              }).toList();

          print('转换完成，返回 ${options.length} 个选项');
          return options;
        } else {
          final errorMsg = '获取投票选项失败: ${responseData['message'] ?? "未知错误"}';
          print(errorMsg);
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = '获取投票选项失败: HTTP ${response.statusCode}';
        print(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('获取投票选项出错: $e');
      print('堆栈跟踪: $stackTrace');
      throw Exception('获取投票选项时出错: $e');
    }
  }

  @override
  Future<MeetingNote?> getNoteDetail(String noteId) async {
    try {
      // 创建HTTP客户端
      final client = http.Client();

      // 构建API请求URL
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/meeting/notes/$noteId');

      // 发送GET请求
      final response = await client.get(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final noteData = responseData['data'];

          // 解析时间
          final DateTime createdAt = DateTime.parse(noteData['createdAt']);
          DateTime? updatedAt;
          if (noteData['updatedAt'] != null) {
            updatedAt = DateTime.parse(noteData['updatedAt']);
          }

          // 获取用户ID
          final noteUserId = noteData['userId'].toString();

          // 获取用户名称
          String creatorName;
          try {
            creatorName = await _userService.getUserNameById(noteUserId);
          } catch (e) {
            // 如果获取用户名失败，则使用备用名称
            creatorName = 'Unknown';
          }

          // 创建MeetingNote对象
          return MeetingNote(
            id: noteData['noteId'].toString(),
            meetingId: noteData['meetingId'].toString(),
            content: noteData['noteContent'],
            noteName: noteData['noteName'],
            creatorId: noteUserId,
            creatorName: creatorName,
            isShared: noteData['isPublic'] == true || noteData['isPublic'] == 1,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: null, // API目前不支持标签
          );
        }
      }

      // 如果请求失败或没有数据，返回null
      print('获取笔记详情失败: HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      print('获取笔记详情出错: $e');
      // 出错时返回null而不是抛出异常，确保UI不会崩溃
      return null;
    }
  }
}
