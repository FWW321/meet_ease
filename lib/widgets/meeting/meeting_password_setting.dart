import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 会议密码设置组件
class MeetingPasswordSetting extends StatefulWidget {
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
  State<MeetingPasswordSetting> createState() => _MeetingPasswordSettingState();
}

class _MeetingPasswordSettingState extends State<MeetingPasswordSetting> {
  // 是否显示密码
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和开关
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color:
                      widget.enablePasswordNotifier.value
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: Text(
                    '会议密码保护',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          widget.enablePasswordNotifier.value
                              ? theme.colorScheme.primary
                              : null,
                    ),
                  ),
                ),
                Switch(
                  value: widget.enablePasswordNotifier.value,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (value) {
                    widget.onEnablePasswordChanged(value);
                    if (!value) {
                      widget.passwordController.clear();
                    }
                    setState(() {});
                  },
                ),
              ],
            ),

            // 密码输入框（仅当启用密码时显示）
            if (widget.enablePasswordNotifier.value) ...[
              const SizedBox(height: AppConstants.paddingM),
              TextFormField(
                controller: widget.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '会议密码 *',
                  hintText: '设置4-16位会议密码',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
                  // 验证密码格式
                  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                    return '密码只能包含字母和数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingS),

              // 安全提示
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        '启用密码后，参会者需要输入正确的密码才能加入会议',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 关闭密码时的提示
              const SizedBox(height: AppConstants.paddingS),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  '不启用密码保护，任何人都可以直接加入会议',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
