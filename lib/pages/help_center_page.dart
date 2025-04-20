import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_constants.dart';

class HelpCenterPage extends HookConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 搜索框
          _buildSearchBar(context),

          const SizedBox(height: 24),

          // 快速问题入口
          _buildQuickQuestions(context),

          const SizedBox(height: 24),

          // 常见问题分类
          _buildFaqSection(
            context,
            title: '会议管理',
            faqs: [
              _Faq(
                question: '如何创建新会议？',
                answer: '您可以在首页点击右下角的"+"按钮，选择"创建会议"，填写会议信息后点击"保存"即可创建新会议。',
              ),
              _Faq(
                question: '如何邀请参会者？',
                answer:
                    '在会议详情页面，点击"参会者"标签，然后点击右上角的"+"按钮，在弹出的搜索框中输入参会者姓名或邮箱，选择要邀请的人员后点击"发送邀请"即可。',
              ),
              _Faq(
                question: '如何修改会议时间？',
                answer:
                    '在会议详情页面，点击右上角的"编辑"按钮，修改会议时间后点击"保存"即可。系统会自动通知所有参会者会议时间变更。',
              ),
              _Faq(
                question: '如何取消会议？',
                answer: '在会议详情页面，点击右上角的"更多"按钮，选择"取消会议"，确认后系统会自动通知所有参会者会议已取消。',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildFaqSection(
            context,
            title: '议程与文档',
            faqs: [
              _Faq(
                question: '如何创建会议议程？',
                answer:
                    '在会议详情页面，切换到"议程"标签，点击"添加议程项"按钮，填写议程标题、负责人和时长后点击"保存"即可添加议程项。',
              ),
              _Faq(
                question: '如何上传会议文档？',
                answer:
                    '在会议详情页面，切换到"文档"标签，点击"上传文档"按钮，选择要上传的文件后点击"上传"即可。上传成功后，所有参会者都可以查看和下载该文档。',
              ),
              _Faq(
                question: '文档支持哪些格式？',
                answer:
                    '目前支持的文档格式包括：PDF、Word(.docx/.doc)、Excel(.xlsx/.xls)、PowerPoint(.pptx/.ppt)和图片文件(.jpg/.png)。',
              ),
              _Faq(
                question: '如何分享会议笔记？',
                answer:
                    '在会议进行页面，切换到"笔记"标签，记录笔记后点击右上角的"分享"按钮，选择分享方式（如发送给参会者、导出为PDF等）即可分享笔记。',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildFaqSection(
            context,
            title: '投票功能',
            faqs: [
              _Faq(
                question: '如何发起投票？',
                answer:
                    '在会议进行页面，切换到"投票"标签，点击"创建投票"按钮，填写投票标题、选项和设置（如匿名投票、多选等）后点击"发起投票"即可。',
              ),
              _Faq(
                question: '如何结束投票？',
                answer:
                    '在投票详情页面，点击"结束投票"按钮即可结束当前投票。结束后，所有参会者都可以查看投票结果，但不能再进行投票操作。',
              ),
              _Faq(
                question: '如何查看历史投票结果？',
                answer:
                    '在会议详情页面，切换到"投票"标签，向下滚动可以看到所有历史投票记录，点击任意投票项可查看详细的投票结果和统计数据。',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildFaqSection(
            context,
            title: '账号与设置',
            faqs: [
              _Faq(
                question: '如何修改个人信息？',
                answer: '在应用底部导航栏点击"我的"，然后点击"个人信息"，进入个人信息页面后可以修改您的姓名、部门、职位等信息。',
              ),
              _Faq(
                question: '如何修改密码？',
                answer:
                    '在"我的"页面，点击"账号与安全"，然后选择"修改密码"，按照提示输入原密码和新密码后点击"确认"即可修改密码。',
              ),
              _Faq(
                question: '如何设置消息通知？',
                answer: '在"我的"页面，点击"通知设置"，可以自定义接收哪些类型的通知，如会议邀请、会议提醒、议程更新等。',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 故障排除
          _buildTroubleshootingSection(context),

          const SizedBox(height: 24),

          // 联系客服
          _buildContactSupport(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 搜索框
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索帮助内容',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      onSubmitted: (value) {
        // TODO: 实现搜索功能
        if (value.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('搜索: $value')));
        }
      },
    );
  }

  // 快速问题入口
  Widget _buildQuickQuestions(BuildContext context) {
    final quickQuestions = [
      _QuickQuestion(
        icon: Icons.add_circle_outline,
        title: '创建会议',
        onTap:
            () => _showAnswer(
              context,
              '如何创建新会议？',
              '您可以在首页点击右下角的"+"按钮，选择"创建会议"，填写会议信息后点击"保存"即可创建新会议。',
            ),
      ),
      _QuickQuestion(
        icon: Icons.people_outline,
        title: '邀请参会者',
        onTap:
            () => _showAnswer(
              context,
              '如何邀请参会者？',
              '在会议详情页面，点击"参会者"标签，然后点击右上角的"+"按钮，在弹出的搜索框中输入参会者姓名或邮箱，选择要邀请的人员后点击"发送邀请"即可。',
            ),
      ),
      _QuickQuestion(
        icon: Icons.list_alt,
        title: '管理议程',
        onTap:
            () => _showAnswer(
              context,
              '如何创建会议议程？',
              '在会议详情页面，切换到"议程"标签，点击"添加议程项"按钮，填写议程标题、负责人和时长后点击"保存"即可添加议程项。',
            ),
      ),
      _QuickQuestion(
        icon: Icons.how_to_vote,
        title: '发起投票',
        onTap:
            () => _showAnswer(
              context,
              '如何发起投票？',
              '在会议进行页面，切换到"投票"标签，点击"创建投票"按钮，填写投票标题、选项和设置（如匿名投票、多选等）后点击"发起投票"即可。',
            ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          child: Text(
            '快速入口',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                quickQuestions.map((question) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: question.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              question.icon,
                              color: Theme.of(context).primaryColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // 常见问题分类
  Widget _buildFaqSection(
    BuildContext context, {
    required String title,
    required List<_Faq> faqs,
  }) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children:
          faqs.map((faq) {
            return ExpansionTile(
              title: Text(faq.question),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  // 故障排除部分
  Widget _buildTroubleshootingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '故障排除',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('遇到问题？请尝试以下步骤：'),
            const SizedBox(height: 8),
            const Text('1. 确保您的应用已更新到最新版本'),
            const Text('2. 检查您的网络连接是否正常'),
            const Text('3. 退出应用后重新启动'),
            const Text('4. 清除应用缓存（设置 > 应用 > MeetEase > 存储 > 清除缓存）'),
            const SizedBox(height: 16),
            const Text('如果问题仍然存在，请联系客服支持。'),
          ],
        ),
      ),
    );
  }

  // 联系客服
  Widget _buildContactSupport(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '联系客服',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('发送邮件'),
              subtitle: const Text('support@meetease.com'),
              onTap: () {
                // TODO: 实现发送邮件功能
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('打开邮件应用')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('客服热线'),
              subtitle: const Text('400-123-4567（工作日 9:00-18:00）'),
              onTap: () {
                // TODO: 实现拨打电话功能
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('拨打客服热线')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('在线客服'),
              subtitle: const Text('工作日 9:00-22:00，节假日 10:00-18:00'),
              onTap: () {
                // TODO: 实现在线客服聊天功能
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('打开在线客服聊天')));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 显示问题回答
  void _showAnswer(BuildContext context, String question, String answer) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(question),
            content: Text(answer),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}

// 快速问题模型
class _QuickQuestion {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _QuickQuestion({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// 常见问题模型
class _Faq {
  final String question;
  final String answer;

  _Faq({required this.question, required this.answer});
}
