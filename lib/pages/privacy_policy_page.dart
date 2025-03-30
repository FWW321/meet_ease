import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PrivacyPolicyPage extends HookConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Center(
              child: Text(
                'MeetEase隐私政策',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '更新日期：2024年6月1日',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            // 引言
            const _PolicySection(
              title: '1. 引言',
              content:
                  '欢迎使用MeetEase（"我们"、"我们的"或"本应用"）。我们十分重视您的隐私和个人信息保护。本隐私政策旨在向您说明我们如何收集、使用、存储和共享您的个人信息，以及您享有的相关权利。\n\n'
                  '请您在使用我们的服务前，仔细阅读并了解本隐私政策。如果您不同意本隐私政策中的任何条款，您应立即停止使用我们的服务。当您使用或继续使用我们的服务，即表示您同意我们按照本隐私政策收集、使用、存储和共享您的相关信息。',
            ),

            // 我们收集的信息
            const _PolicySection(
              title: '2. 我们收集的信息',
              content:
                  '2.1 您主动提供的信息\n'
                  '• 账号信息：当您注册MeetEase账号时，我们会收集您提供的姓名、电子邮件地址、手机号码、密码等信息。\n'
                  '• 个人资料：您可以选择提供您的职位、部门、头像等信息来完善个人资料。\n'
                  '• 会议相关信息：您创建或参与的会议信息，包括会议主题、时间、地点、参会人员、议程、笔记、文档、投票等内容。\n\n'
                  '2.2 我们自动收集的信息\n'
                  '• 设备信息：我们会收集您使用的设备型号、操作系统版本、设备标识符、IP地址等信息。\n'
                  '• 日志信息：包括您的搜索查询内容、IP地址、浏览器类型、访问日期和时间、停留时长等信息。\n'
                  '• 位置信息：经您授权，我们可能会收集您的位置信息，以便为您提供基于位置的服务（如会议室推荐）。\n\n'
                  '2.3 来自第三方的信息\n'
                  '我们可能从第三方合作伙伴获取您的某些信息，例如当您使用第三方账号登录我们的服务时，我们会获取您授权的账号信息。',
            ),

            // 我们如何使用您的信息
            const _PolicySection(
              title: '3. 我们如何使用您的信息',
              content:
                  '我们使用收集到的信息用于以下目的：\n\n'
                  '3.1 提供服务\n'
                  '• 创建和维护您的账号\n'
                  '• 处理您的会议预订和管理\n'
                  '• 提供会议议程、文档、笔记和投票等功能\n'
                  '• 发送会议通知和提醒\n'
                  '• 响应您的查询和请求\n\n'
                  '3.2 改进和开发服务\n'
                  '• 了解用户如何使用我们的服务\n'
                  '• 改进现有功能和开发新功能\n'
                  '• 进行数据分析和研究\n'
                  '• 监测和防止技术问题\n\n'
                  '3.3 安全与合规\n'
                  '• 验证您的身份\n'
                  '• 保护我们的服务安全\n'
                  '• 防止欺诈和滥用行为\n'
                  '• 遵守法律法规的要求',
            ),

            // 信息共享
            const _PolicySection(
              title: '4. 信息共享',
              content:
                  '我们重视您的隐私，不会将您的个人信息出售给第三方。我们可能在以下情况下共享您的信息：\n\n'
                  '4.1 经您同意的共享\n'
                  '• 当您使用会议邀请功能时，您的姓名和电子邮件地址将与被邀请人共享\n'
                  '• 当您参与会议时，您的参会信息将与会议组织者和其他参会者共享\n\n'
                  '4.2 与服务提供商的共享\n'
                  '我们可能会与提供技术、数据分析、存储等服务的第三方服务提供商共享信息，这些服务提供商仅能为我们提供服务的目的处理您的信息，不得将其用于其他目的。\n\n'
                  '4.3 法律要求的共享\n'
                  '如果法律法规要求披露，或者为了响应合法的法律程序（如法院命令或传票），我们可能会共享您的信息。\n\n'
                  '4.4 保护权益的共享\n'
                  '为了保护MeetEase、我们的用户或公众的权利、财产或安全免受损害时，我们可能会共享您的信息。',
            ),

            // 信息存储与安全
            const _PolicySection(
              title: '5. 信息存储与安全',
              content:
                  '5.1 信息存储\n'
                  '我们会在为您提供服务所必需的时间内保留您的个人信息，除非需要延长保留期或法律允许。\n\n'
                  '5.2 信息安全\n'
                  '我们采取各种安全技术和程序，以防止信息的丢失、不当使用、未经授权的访问或披露：\n'
                  '• 使用加密技术保护数据传输和存储\n'
                  '• 实施严格的数据访问控制\n'
                  '• 定期安全评估和审计\n\n'
                  '尽管我们竭尽全力保护您的信息安全，但请理解互联网传输不可能百分之百安全，我们无法保证您的信息绝对安全。',
            ),

            // 您的权利
            const _PolicySection(
              title: '6. 您的权利',
              content:
                  '根据适用的法律法规，您可能享有以下权利：\n\n'
                  '• 访问权：您有权访问我们持有的关于您的个人信息\n'
                  '• 更正权：您有权要求我们更正不准确的个人信息\n'
                  '• 删除权：在特定情况下，您有权要求删除您的个人信息\n'
                  '• 反对权：您有权反对我们处理您的个人信息\n'
                  '• 限制权：您有权要求限制处理您的个人信息\n'
                  '• 数据可携带权：您有权以结构化、常用和机器可读的格式接收您的个人信息\n\n'
                  '如您想行使上述权利，请通过本政策末尾提供的联系方式与我们联系。',
            ),

            // 儿童隐私
            const _PolicySection(
              title: '7. 儿童隐私',
              content:
                  '我们的服务不面向16岁以下的儿童。我们不会故意收集16岁以下儿童的个人信息。如果您发现我们无意中收集了16岁以下儿童的个人信息，请立即通知我们，我们会采取措施删除相关信息。',
            ),

            // 隐私政策的变更
            const _PolicySection(
              title: '8. 隐私政策的变更',
              content:
                  '我们可能会不时更新本隐私政策。当我们对本隐私政策做出重大变更时，我们会在本页面发布更新后的政策，并在变更生效前通过应用内通知或其他方式通知您。我们鼓励您定期查阅本隐私政策，以了解我们如何保护您的信息。',
            ),

            // 联系我们
            const _PolicySection(
              title: '9. 联系我们',
              content:
                  '如果您对本隐私政策有任何疑问、意见或建议，请通过以下方式与我们联系：\n\n'
                  '电子邮件：privacy@meetease.com\n'
                  '邮寄地址：中国北京市海淀区科学院南路2号\n'
                  '电话：400-123-4567\n\n'
                  '我们将在收到您的请求后30天内回复。',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
