import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/fubao_repository.dart';
import '../../design/fubao_colors.dart';
import '../../widgets/fubao_widgets.dart';

enum ProfileSettingKind {
  notifications,
  family,
  health,
  device,
  reminder,
  privacy,
  help,
  font,
  reading,
  contact,
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({
    required this.kind,
    this.elder = false,
    this.repository,
    super.key,
  });
  final ProfileSettingKind kind;
  final bool elder;
  final FubaoRepository? repository;

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool enabled = true;
  bool dnd = true;
  double value = 60;
  bool busy = false;
  final feedbackController = TextEditingController();

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  String get title => switch (widget.kind) {
        ProfileSettingKind.notifications => '消息通知',
        ProfileSettingKind.family => '家庭成员',
        ProfileSettingKind.health => '健康档案',
        ProfileSettingKind.device => '设备管理',
        ProfileSettingKind.reminder => '提醒与勿扰',
        ProfileSettingKind.privacy => '隐私与数据',
        ProfileSettingKind.help => '帮助与反馈',
        ProfileSettingKind.font => '字体大小',
        ProfileSettingKind.reading => '朗读设置',
        ProfileSettingKind.contact => '联系家人',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: ListView(
          padding: EdgeInsets.all(widget.elder ? 24 : 18),
          children: _content(context),
        ),
      );

  List<Widget> _content(BuildContext context) => switch (widget.kind) {
        ProfileSettingKind.family => [
            _member('小雨', '子女主账号', Icons.favorite_rounded),
            const SizedBox(height: 12),
            _member('王阿姨', '长辈账号', Icons.wb_sunny_rounded),
          ],
        ProfileSettingKind.health => [
            _info('称呼', '妈妈'),
            _info('慢病类型', '高血压'),
            _info('身高 / 体重', '162 cm / 58.5 kg'),
            _info('档案授权', '已确认'),
          ],
        ProfileSettingKind.device => [
            _info('福豹家庭智能体', '在线 · 固件 1.0.0'),
            const SizedBox(height: 18),
            Text('设备音量 ${value.round()}%',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: (next) => setState(() => value = next)),
            SwitchListTile(
                value: enabled,
                onChanged: (next) => setState(() => enabled = next),
                title: const Text('设备语音提醒')),
          ],
        ProfileSettingKind.notifications => _switches('任务完成通知'),
        ProfileSettingKind.reminder => [
            ..._switches('每日任务提醒'),
            SwitchListTile(
                value: dnd,
                onChanged: (next) => setState(() => dnd = next),
                title: const Text('勿扰时段'),
                subtitle: const Text('22:00 至次日 07:00')),
          ],
        ProfileSettingKind.privacy => [
            _info('健康数据', '仅家庭成员可查看'),
            _info('手机号', '已加密保存'),
            _info('设备数据', '解绑后保留 90 天'),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: busy ? null : _exportData,
              icon: const Icon(Icons.download_rounded),
              label: const Text('导出我的数据'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                foregroundColor: FubaoColors.orangeStrong,
              ),
              onPressed: busy ? null : _scheduleDeletion,
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('申请注销账号'),
            ),
            const SizedBox(height: 8),
            const Text(
              '注销申请提交后进入 30 天删除队列；退出登录或退出家庭组不会删除账号。',
              textAlign: TextAlign.center,
              style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12),
            ),
          ],
        ProfileSettingKind.help => [
            _info('常见问题', '登录、家庭绑定、任务和设备使用说明'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '告诉我们遇到的问题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _submitFeedback,
              child: const Text('提交反馈'),
            ),
          ],
        ProfileSettingKind.font => [
            Text('文字大小示例',
                style: TextStyle(
                    fontSize: 18 + value / 8, fontWeight: FontWeight.w700)),
            Slider(
                value: value,
                min: 20,
                max: 100,
                onChanged: (next) => setState(() => value = next)),
          ],
        ProfileSettingKind.reading => [
            Text('朗读速度 ${value.round()}%'),
            Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: (next) => setState(() => value = next)),
            const SizedBox(height: 12),
            const ReadAloudButton(text: '这是一段福豹朗读设置的试听内容。'),
          ],
        ProfileSettingKind.contact => [
            _member('小雨', '子女 · 已绑定', Icons.phone_rounded),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: () => _notice('调试环境未配置系统拨号权限。'),
                icon: const Icon(Icons.phone_rounded),
                label: const Text('联系小雨')),
          ],
      };

  List<Widget> _switches(String firstTitle) => [
        SwitchListTile(
            value: enabled,
            onChanged: (next) => setState(() => enabled = next),
            title: Text(firstTitle)),
        SwitchListTile(
            value: dnd,
            onChanged: (next) => setState(() => dnd = next),
            title: const Text('健康提醒')),
      ];

  Widget _info(String label, String value) => FubaoCard(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(color: FubaoColors.inkMuted))
        ]),
      );

  Widget _member(String name, String subtitle, IconData icon) => FubaoCard(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: FubaoColors.mintSoft,
              child: Icon(icon, color: FubaoColors.mintStrong)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(color: FubaoColors.inkMuted))
              ]))
        ]),
      );

  void _notice(String message) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(content: Text(message), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'))
          ]));

  Future<void> _exportData() async {
    if (widget.repository == null) {
      _notice('请登录后再导出数据。');
      return;
    }
    setState(() => busy = true);
    try {
      final data = await widget.repository!.exportData();
      final text = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _notice('数据已生成并复制到剪贴板，可粘贴保存为 JSON 文件。');
    } catch (error) {
      if (mounted) _notice('导出失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _scheduleDeletion() async {
    if (widget.repository == null) {
      _notice('请登录后再申请注销。');
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('申请注销账号？'),
            content: const Text('账号与个人数据将在 30 天后删除。此操作不同于退出登录或退出家庭组。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: FubaoColors.orangeStrong,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认申请'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => busy = true);
    try {
      final deleteAfter = await widget.repository!.scheduleAccountDeletion();
      if (mounted) {
        _notice(
            '注销申请已提交，预计 ${deleteAfter.year}年${deleteAfter.month}月${deleteAfter.day}日删除。');
      }
    } catch (error) {
      if (mounted) _notice('提交失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submitFeedback() async {
    final content = feedbackController.text.trim();
    if (content.isEmpty) {
      _notice('请先填写反馈内容。');
      return;
    }
    if (widget.repository == null) {
      _notice('请登录后再提交反馈。');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.repository!.submitFeedback(content);
      feedbackController.clear();
      if (mounted) _notice('反馈已提交，感谢你的帮助。');
    } catch (error) {
      if (mounted) _notice('提交失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({required this.onLogout, super.key});
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('账号设置'), centerTitle: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const FubaoCard(
              padding: EdgeInsets.all(18),
              child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone_iphone_rounded,
                      color: FubaoColors.mintStrong),
                  title: Text('当前账号'),
                  subtitle: Text('手机号验证码安全登录'))),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                foregroundColor: FubaoColors.orangeStrong),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
          ),
          const SizedBox(height: 10),
          const Text('退出登录不会退出家庭组，也不会删除健康档案和任务数据。',
              textAlign: TextAlign.center,
              style: TextStyle(color: FubaoColors.inkMuted)),
        ]),
      );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('退出登录？'),
                    content: const Text('你将返回手机号登录页面，家庭关系保持不变。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('退出登录'))
                    ])) ??
        false;
    if (!confirmed || !context.mounted) return;
    Navigator.pop(context);
    await onLogout();
  }
}
