import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/webrtc_providers.dart';
import '../services/webrtc_service.dart';

/// 参会人员查看组件
class ParticipantsWidget extends ConsumerWidget {
  final String meetingId;

  const ParticipantsWidget({required this.meetingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取参会人员列表
    final participantsAsync = ref.watch(webRTCParticipantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('参会人员'), centerTitle: true),
      body: participantsAsync.when(
        data: (participants) => _buildParticipantsList(participants, context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '获取参会人员失败\n',
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
    );
  }

  // 构建参会人员列表
  Widget _buildParticipantsList(
    List<MeetingParticipant> participants,
    BuildContext context,
  ) {
    if (participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无参会人员', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantItem(participant, context);
      },
    );
  }

  // 构建参会人员项
  Widget _buildParticipantItem(
    MeetingParticipant participant,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor:
              participant.isMe ? Colors.blue : Colors.grey.shade300,
          child: Text(
            participant.name.isNotEmpty
                ? participant.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: 18,
              color: participant.isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              participant.name,
              style: TextStyle(
                fontWeight:
                    participant.isMe ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            if (participant.isMe)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('(我)', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              // 麦克风状态图标
              Icon(
                participant.isMuted ? Icons.mic_off : Icons.mic,
                color: participant.isMuted ? Colors.red : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                participant.isMuted ? '已静音' : '可发言',
                style: TextStyle(
                  color: participant.isMuted ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing:
            participant.isSpeaking
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '发言中',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                )
                : null,
      ),
    );
  }
}
