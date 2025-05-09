import 'package:flutter/material.dart';

/// 会议密码设置组件
class MeetingPasswordSetting extends StatelessWidget {
  final ValueNotifier<bool> enablePasswordNotifier;
  final TextEditingController passwordController;
  final Function(bool) onEnablePasswordChanged;

  const MeetingPasswordSetting({
    super.key,
    required this.enablePasswordNotifier,
    required this.passwordController,
    required this.onEnablePasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '会议密码',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: enablePasswordNotifier.value,
                  onChanged: (value) {
                    onEnablePasswordChanged(value);
                    if (!value) {
                      passwordController.clear();
                    }
                  },
                ),
              ],
            ),
            // 只有启用密码时才显示密码输入框
            if (enablePasswordNotifier.value)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true, // 隐藏密码
                    decoration: const InputDecoration(
                      labelText: '设置密码',
                      hintText: '参会者需要输入此密码才能加入会议',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入会议密码';
                      }
                      if (value.length < 4) {
                        return '密码长度至少为4位';
                      }
                      if (value.length > 16) {
                        return '密码长度不能超过16位';
                      }
                      // 验证密码格式，可以根据需要增加字母、数字等要求
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                        return '密码只能包含字母和数字';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '启用密码后，参会者需要输入正确的密码才能加入会议。',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              )
            else
              const Text(
                '不启用密码，所有参会者可直接加入会议。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
