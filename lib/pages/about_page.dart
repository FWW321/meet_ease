import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于我们')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 应用图标
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.calendar_month,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),

            const SizedBox(height: 16),

            // 应用名称和版本
            Text(
              'MeetEase',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '版本 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // 图标生成工具
            const Divider(),
            const SizedBox(height: 10),
            const Text('开发工具', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('应用图标生成器'),
              subtitle: const Text('修改应用图标'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, AppConstants.iconGeneratorRoute);
              },
            ),

            const SizedBox(height: 40),

            // 介绍文本
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'MeetEase是一款专注于提升会议效率的智能会议管理平台，'
                '提供议程管理、文档共享、笔记协作和投票决策等功能，'
                '让您的每一次会议都能更加高效和有价值。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            const SizedBox(height: 40),

            // 功能特点
            _buildSection(
              context,
              title: '功能特点',
              children: [
                _buildFeatureItem(
                  context,
                  icon: Icons.event_note,
                  title: '智能议程管理',
                  description: '轻松创建和管理会议议程，实时跟踪进度',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.folder_shared,
                  title: '文档共享',
                  description: '便捷分享和管理会议相关文档，支持在线预览',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.note_alt,
                  title: '协作笔记',
                  description: '与参会者共同记录和编辑会议笔记，提高团队协作效率',
                ),
                _buildFeatureItem(
                  context,
                  icon: Icons.how_to_vote,
                  title: '投票决策',
                  description: '快速创建投票，实时查看投票结果，辅助团队决策',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 联系我们
            _buildSection(
              context,
              title: '联系我们',
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('电子邮件'),
                  subtitle: const Text('support@meetease.com'),
                  onTap: () => _launchUrl('mailto:support@meetease.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.web),
                  title: const Text('官方网站'),
                  subtitle: const Text('www.meetease.com'),
                  onTap: () => _launchUrl('https://www.meetease.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('客服热线'),
                  subtitle: const Text('400-123-4567'),
                  onTap: () => _launchUrl('tel:4001234567'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 开发团队
            _buildSection(
              context,
              title: '开发团队',
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'MeetEase由一支充满激情的开发团队创建，'
                    '团队成员来自不同的背景，但都有着共同的目标——'
                    '打造最佳的会议管理体验，让会议变得更加高效和有价值。',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 版权信息
            const Text(
              '© 2023-2024 MeetEase. 保留所有权利。',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 构建分区
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }

  // 构建功能特点项
  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 打开URL
  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('无法打开 $url');
    }
  }
}
