import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/fubao_repository.dart';
import '../../data/accessibility_settings.dart';
import '../../data/local_data_store.dart';
import '../../data/notification_permission_service.dart';
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
  bool healthReminderEnabled = true;
  bool dnd = true;
  TimeOfDay dndStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay dndEnd = const TimeOfDay(hour: 7, minute: 0);
  double value = 60;
  double speechRate = 50;
  bool deviceOnline = true;
  bool busy = false;
  bool loadingData = false;
  String? dataError;
  Map<String, dynamic> familyData = const {};
  Map<String, dynamic> healthData = const {};
  Map<String, dynamic> deviceData = const {};
  bool accessibilityInitialized = false;
  final feedbackController = TextEditingController();
  final LocalDataStore reminderStore = PlatformLocalDataStore();

  @override
  void initState() {
    super.initState();
    if (widget.kind == ProfileSettingKind.notifications) enabled = false;
    if (widget.kind == ProfileSettingKind.reminder) _loadReminderSettings();
    _loadData();
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (accessibilityInitialized) return;
    final settings = AccessibilitySettingsScope.maybeOf(context);
    if (widget.kind == ProfileSettingKind.font) {
      value = (settings?.textScale ?? 1) * 100;
    } else if (widget.kind == ProfileSettingKind.reading) {
      value = (settings?.speechRate ?? 0.5) * 100;
    }
    accessibilityInitialized = true;
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

  List<Widget> _content(BuildContext context) {
    if (loadingData) {
      return const [
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (dataError != null) {
      return [
        FubaoCard(
          child: Column(children: [
            const Icon(Icons.cloud_off_rounded,
                color: FubaoColors.orangeStrong, size: 36),
            const SizedBox(height: 10),
            Text(dataError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadData, child: const Text('重新加载')),
          ]),
        ),
      ];
    }
    return switch (widget.kind) {
      ProfileSettingKind.family => _familyContent(),
      ProfileSettingKind.health => _healthContent(),
      ProfileSettingKind.device => _deviceContent(context),
      ProfileSettingKind.notifications => _notificationSwitches(),
      ProfileSettingKind.reminder => _reminderContent(),
      ProfileSettingKind.privacy => [
          _info('健康数据', '仅家庭成员可查看'),
          _info('手机号', '已加密保存'),
          _info('设备数据', '解绑后保留 90 天'),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
            icon: const Icon(Icons.policy_outlined),
            label: const Text('查看隐私政策'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('查看用户服务协议'),
          ),
          const SizedBox(height: 10),
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
          const Text('文字大小示例',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text('当前 ${value.round()}%',
              style: const TextStyle(color: FubaoColors.inkMuted)),
          Slider(
              value: value,
              min: 90,
              max: 140,
              divisions: 10,
              onChanged: (next) {
                setState(() => value = next);
                AccessibilitySettingsScope.maybeOf(context)
                    ?.setTextScale(next / 100);
              }),
        ],
      ProfileSettingKind.reading => [
          Text('朗读速度 ${value.round()}%'),
          Slider(
              value: value,
              min: 30,
              max: 80,
              divisions: 10,
              onChanged: (next) {
                setState(() => value = next);
                AccessibilitySettingsScope.maybeOf(context)
                    ?.setSpeechRate(next / 100);
              }),
          const SizedBox(height: 12),
          ReadAloudButton(
            text: '这是一段福豹朗读设置的试听内容。',
            rate: value / 100,
          ),
        ],
      ProfileSettingKind.contact => _contactContent(),
    };
  }

  bool get _loadsRepositoryData => switch (widget.kind) {
        ProfileSettingKind.family ||
        ProfileSettingKind.health ||
        ProfileSettingKind.device ||
        ProfileSettingKind.contact =>
          true,
        _ => false,
      };

  Future<void> _loadData() async {
    if (!_loadsRepositoryData || widget.repository == null) return;
    setState(() {
      loadingData = true;
      dataError = null;
    });
    try {
      switch (widget.kind) {
        case ProfileSettingKind.family:
        case ProfileSettingKind.contact:
          familyData = await widget.repository!.familyDetails();
          break;
        case ProfileSettingKind.health:
          healthData = await widget.repository!.elderHealthProfile();
          break;
        case ProfileSettingKind.device:
          deviceData = await widget.repository!.currentDevice();
          final settings =
              (deviceData['settings'] as Map?)?.cast<String, dynamic>() ??
                  const {};
          value = (settings['volume'] as num?)?.toDouble() ?? 60;
          speechRate = (settings['speechRate'] as num?)?.toDouble() ?? 50;
          dnd = settings['dndEnabled'] != false;
          deviceOnline = deviceData['status'] == 'online';
          break;
        default:
          break;
      }
    } catch (error) {
      dataError = '加载失败：$error';
    } finally {
      if (mounted) setState(() => loadingData = false);
    }
  }

  List<Widget> _familyContent() {
    final members = (familyData['members'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    if (members.isEmpty) return [_info('家庭成员', '暂无已绑定成员')];
    return [
      for (var index = 0; index < members.length; index++) ...[
        _member(
          members[index]['nickname']?.toString() ?? '家庭成员',
          members[index]['role'] == 'child' ? '子女主账号' : '长辈账号',
          members[index]['role'] == 'child'
              ? Icons.favorite_rounded
              : Icons.wb_sunny_rounded,
        ),
        if (index != members.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _healthContent() {
    final conditions = (healthData['chronicConditions'] as List? ?? const [])
        .map((item) => item.toString())
        .join('、');
    final height = healthData['heightCm'];
    final weight = healthData['weightKg'];
    final name = healthData['relativeName']?.toString() ?? '--';
    return [
      _HealthIdentityHeader(
        name: name,
        consented: healthData['consentAt'] != null,
      ),
      const SizedBox(height: 16),
      _HealthSection(
        title: '基本信息',
        icon: Icons.badge_outlined,
        rows: [
          (
            '身高 / 体重',
            '${height ?? '--'} cm / ${weight ?? '--'} kg',
          ),
        ],
      ),
      const SizedBox(height: 14),
      _HealthSection(
        title: '健康状况',
        icon: Icons.monitor_heart_outlined,
        rows: [
          ('慢病类型', conditions.isEmpty ? '未填写' : conditions),
          ('用药史', _profileValue(healthData['medicationHistory'])),
          ('既往病史', _profileValue(healthData['medicalHistory'])),
        ],
      ),
      const SizedBox(height: 14),
      _HealthSection(
        title: '安全与授权',
        icon: Icons.verified_user_outlined,
        rows: [
          ('紧急联系人', healthData['emergencyContact']?.toString() ?? '未填写'),
          ('档案授权', healthData['consentAt'] == null ? '未确认' : '已确认'),
        ],
      ),
      if (!widget.elder) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : _editHealthProfile,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('编辑健康档案'),
        ),
      ],
    ];
  }

  String _profileValue(Object? value) {
    if (value == null) return '未填写';
    if (value is List) {
      final text = value.map((item) => item.toString()).join('、');
      return text.isEmpty ? '未填写' : text;
    }
    if (value is Map) {
      final text = value.values
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString())
          .join('、');
      return text.isEmpty ? '未填写' : text;
    }
    final text = value.toString().trim();
    return text.isEmpty ? '未填写' : text;
  }

  List<Widget> _deviceContent(BuildContext context) {
    final status = deviceData['status']?.toString();
    if (status == 'unbound' || deviceData.isEmpty) {
      return [
        const FubaoCard(
          padding: EdgeInsets.all(24),
          child: Column(children: [
            Icon(Icons.radar_rounded, size: 52, color: FubaoColors.mintStrong),
            SizedBox(height: 12),
            Text('当前没有绑定设备',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('发现附近的福豹设备后，可重新完成配网和激活',
                textAlign: TextAlign.center,
                style: TextStyle(color: FubaoColors.inkMuted)),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : _discoverDevice,
          icon: const Icon(Icons.radar_rounded),
          label: const Text('发现设备'),
        ),
      ];
    }
    if (status == 'discovered') {
      return [
        _info(
          deviceData['serialNumber']?.toString() ?? '福豹家庭智能体',
          '已发现 · 等待激活',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : _activateDevice,
          icon: const Icon(Icons.wifi_tethering_rounded),
          label: const Text('模拟配网并激活'),
        ),
      ];
    }
    return [
      _info(
        deviceData['serialNumber']?.toString() ?? '福豹家庭智能体',
        '${_deviceStatusLabel(deviceData['status']?.toString())} · 固件 ${deviceData['firmware'] ?? '--'}',
      ),
      const SizedBox(height: 18),
      Text('设备音量 ${value.round()}%',
          style: Theme.of(context).textTheme.titleMedium),
      Slider(
        value: value,
        min: 0,
        max: 100,
        onChanged: busy ? null : (next) => setState(() => value = next),
        onChangeEnd: busy ? null : (_) => _saveDeviceSettings(),
      ),
      Text('朗读速度 ${speechRate.round()}%',
          style: Theme.of(context).textTheme.titleMedium),
      Slider(
        value: speechRate,
        min: 0,
        max: 100,
        onChanged: busy ? null : (next) => setState(() => speechRate = next),
        onChangeEnd: busy ? null : (_) => _saveDeviceSettings(),
      ),
      SwitchListTile(
        value: deviceOnline,
        onChanged: busy ? null : _setDeviceOnline,
        title: const Text('模拟设备在线'),
      ),
      SwitchListTile(
        value: dnd,
        onChanged: busy
            ? null
            : (next) {
                setState(() => dnd = next);
                _saveDeviceSettings();
              },
        title: const Text('勿扰时段'),
        subtitle: const Text('22:00 至次日 07:00'),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: busy ? null : _factoryResetDevice,
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('模拟恢复出厂设置'),
      ),
      const SizedBox(height: 10),
      FilledButton.tonalIcon(
        style:
            FilledButton.styleFrom(foregroundColor: FubaoColors.orangeStrong),
        onPressed: busy ? null : _unbindDevice,
        icon: const Icon(Icons.link_off_rounded),
        label: const Text('解绑设备'),
      ),
      const SizedBox(height: 8),
      const Text('解绑后健康数据保留 90 天；恢复出厂会清除设备配置。',
          textAlign: TextAlign.center,
          style: TextStyle(color: FubaoColors.inkMuted, fontSize: 12)),
    ];
  }

  List<Widget> _contactContent() {
    final members = (familyData['members'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    final targetRole = widget.elder ? 'child' : 'elder';
    Map<String, dynamic>? target;
    for (final member in members) {
      if (member['role'] == targetRole) {
        target = member;
        break;
      }
    }
    final name = target?['nickname']?.toString() ?? '家人';
    return [
      _member(name, '${widget.elder ? '子女' : '长辈'} · 已绑定', Icons.phone_rounded),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => _notice('已复制 $name 的联系提示；真机拨号需在 iOS 权限配置后启用。'),
        icon: const Icon(Icons.phone_rounded),
        label: Text('联系$name'),
      ),
    ];
  }

  String _deviceStatusLabel(String? status) => switch (status) {
        'online' => '在线',
        'offline' => '离线',
        'unbound' => '已解绑',
        'discovered' => '待激活',
        _ => '状态未知',
      };

  Future<void> _discoverDevice() async {
    if (widget.repository == null || busy) return;
    setState(() => busy = true);
    try {
      deviceData = await widget.repository!.discoverDevice();
    } catch (error) {
      if (mounted) _notice('发现设备失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _activateDevice() async {
    if (widget.repository == null || busy) return;
    final serial = deviceData['serialNumber']?.toString();
    if (serial == null || serial.isEmpty) return;
    setState(() => busy = true);
    try {
      deviceData = await widget.repository!.activateDevice(
        serial,
        '家庭 Wi-Fi',
      );
      deviceOnline = deviceData['status'] == 'online';
      if (mounted) _notice('设备已重新激活。');
    } catch (error) {
      if (mounted) _notice('设备激活失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _saveDeviceSettings() async {
    if (widget.repository == null || busy) return;
    setState(() => busy = true);
    try {
      final settings = await widget.repository!.updateDeviceSettings({
        'volume': value.round(),
        'speechRate': speechRate.round(),
        'dndEnabled': dnd,
        'dndStart': '22:00',
        'dndEnd': '07:00',
      });
      deviceData = {...deviceData, 'settings': settings};
    } catch (error) {
      if (mounted) _notice('设备设置保存失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editHealthProfile() async {
    if (widget.repository == null) return;
    final edited = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _HealthProfileEditDialog(initial: healthData),
    );
    if (edited == null) return;
    setState(() => busy = true);
    try {
      healthData = await widget.repository!.updateElderHealthProfile({
        ...edited,
        'consentConfirmed': true,
      });
      if (mounted) _notice('健康档案已更新。');
    } catch (error) {
      if (mounted) _notice('健康档案保存失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _setDeviceOnline(bool next) async {
    if (widget.repository == null) return;
    setState(() => busy = true);
    try {
      deviceData = await widget.repository!.setDeviceOnline(next);
      if (mounted) setState(() => deviceOnline = next);
    } catch (error) {
      if (mounted) _notice('设备状态更新失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _factoryResetDevice() async {
    if (widget.repository == null) return;
    final confirmed = await _confirm(
      title: '恢复出厂设置？',
      content: '设备保持绑定，音量、朗读速度和勿扰设置恢复默认值。',
      action: '确认恢复',
    );
    if (!confirmed) return;
    setState(() => busy = true);
    try {
      deviceData = await widget.repository!.factoryResetDevice();
      final settings =
          (deviceData['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
      value = (settings['volume'] as num?)?.toDouble() ?? 60;
      speechRate = (settings['speechRate'] as num?)?.toDouble() ?? 50;
      dnd = settings['dndEnabled'] != false;
      deviceOnline = deviceData['status'] == 'online';
      if (mounted) _notice('设备参数已恢复默认值，绑定关系保持不变。');
    } catch (error) {
      if (mounted) _notice('恢复失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _unbindDevice() async {
    if (widget.repository == null) return;
    final confirmed = await _confirm(
      title: '解绑设备？',
      content: '设备将停止同步，已有健康数据保留 90 天。此操作不会退出家庭组。',
      action: '确认解绑',
    );
    if (!confirmed) return;
    setState(() => busy = true);
    try {
      final result = await widget.repository!.unbindDevice();
      deviceData = const {'status': 'unbound'};
      deviceOnline = false;
      final retainUntil =
          DateTime.tryParse(result['dataRetainedUntil']?.toString() ?? '');
      if (mounted) {
        _notice(retainUntil == null
            ? '设备已解绑，健康数据将保留 90 天。'
            : '设备已解绑，数据保留至 ${retainUntil.year}年${retainUntil.month}月${retainUntil.day}日。');
      }
    } catch (error) {
      if (mounted) _notice('解绑失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  List<Widget> _reminderContent() {
    final canUseDnd = enabled || healthReminderEnabled;
    return [
      SwitchListTile(
        key: const Key('task-reminder-switch'),
        value: enabled,
        onChanged: (next) => _setReminderToggle(task: next),
        title: const Text('每日任务提醒'),
        subtitle: const Text('按计划时间提醒长辈完成今日任务'),
      ),
      SwitchListTile(
        key: const Key('health-reminder-switch'),
        value: healthReminderEnabled,
        onChanged: (next) => _setReminderToggle(health: next),
        title: const Text('健康提醒'),
        subtitle: const Text('健康数据异常或需要复测时提醒'),
      ),
      const Divider(),
      SwitchListTile(
        key: const Key('dnd-switch'),
        value: canUseDnd && dnd,
        onChanged: canUseDnd
            ? (next) {
                setState(() => dnd = next);
                _saveReminderSettings();
              }
            : null,
        title: const Text('勿扰时段'),
        subtitle: Text(canUseDnd
            ? '${_timeValue(dndStart)} 至次日 ${_timeValue(dndEnd)}'
            : '开启任意一种提醒后可设置'),
      ),
      if (canUseDnd && dnd) ...[
        ListTile(
          leading: const Icon(Icons.nights_stay_outlined,
              color: FubaoColors.mintStrong),
          title: const Text('开始时间'),
          trailing: Text(_timeValue(dndStart),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          onTap: () => _pickDndTime(start: true),
        ),
        ListTile(
          leading: const Icon(Icons.wb_sunny_outlined,
              color: FubaoColors.orangeStrong),
          title: const Text('结束时间'),
          trailing: Text(_timeValue(dndEnd),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          onTap: () => _pickDndTime(start: false),
        ),
      ],
    ];
  }

  void _setReminderToggle({bool? task, bool? health}) {
    setState(() {
      if (task != null) enabled = task;
      if (health != null) healthReminderEnabled = health;
      if (!enabled && !healthReminderEnabled) dnd = false;
    });
    _saveReminderSettings();
  }

  Future<void> _pickDndTime({required bool start}) async {
    final current = start ? dndStart : dndEnd;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        dndStart = picked;
      } else {
        dndEnd = picked;
      }
    });
    await _saveReminderSettings();
  }

  String get _reminderKey =>
      'fubao-reminders-${widget.elder ? 'elder' : 'child'}-v1';

  Future<void> _loadReminderSettings() async {
    final raw = await reminderStore.read(_reminderKey);
    if (raw == null || !mounted) return;
    try {
      final data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      setState(() {
        enabled = data['taskEnabled'] != false;
        healthReminderEnabled = data['healthEnabled'] != false;
        dnd = data['dndEnabled'] == true && (enabled || healthReminderEnabled);
        dndStart = _parseTime(data['dndStart']?.toString(), dndStart);
        dndEnd = _parseTime(data['dndEnd']?.toString(), dndEnd);
      });
    } catch (_) {
      // Invalid local preferences fall back to the safe defaults.
    }
  }

  Future<void> _saveReminderSettings() => reminderStore.write(
        _reminderKey,
        jsonEncode({
          'taskEnabled': enabled,
          'healthEnabled': healthReminderEnabled,
          'dndEnabled': dnd,
          'dndStart': _timeValue(dndStart),
          'dndEnd': _timeValue(dndEnd),
        }),
      );

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeValue(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  List<Widget> _notificationSwitches() => [
        SwitchListTile(
          value: enabled,
          onChanged: busy ? null : _setNotificationsEnabled,
          title: const Text('任务完成通知'),
          subtitle: const Text('首次开启时由 iOS 请求通知权限'),
        ),
        SwitchListTile(
          value: dnd,
          onChanged: (next) => setState(() => dnd = next),
          title: const Text('健康提醒'),
        ),
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

  Future<void> _setNotificationsEnabled(bool next) async {
    if (!next) {
      setState(() => enabled = false);
      return;
    }
    setState(() => busy = true);
    try {
      final result = await NotificationPermissionService().request();
      if (!result.authorized) {
        if (mounted) _notice('通知权限未开启，可稍后在 iPhone 系统设置中允许。');
        return;
      }
      if (result.deviceToken != null && widget.repository != null) {
        await widget.repository!.registerPushToken(result.deviceToken!);
      }
      if (mounted) setState(() => enabled = true);
    } catch (error) {
      if (mounted) _notice('通知设置失败：$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _HealthIdentityHeader extends StatelessWidget {
  const _HealthIdentityHeader({required this.name, required this.consented});
  final String name;
  final bool consented;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEAF8F2), Color(0xFFF8FCFA)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FubaoColors.borderMint),
        ),
        child: Row(children: [
          const CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded,
                size: 36, color: FubaoColors.mintStrong),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('个人健康档案',
                    style: TextStyle(color: FubaoColors.inkMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: consented ? FubaoColors.mintSoft : const Color(0xFFFFF1E7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              consented ? '已授权' : '待授权',
              style: TextStyle(
                color:
                    consented ? FubaoColors.mintDeep : FubaoColors.orangeStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ]),
      );
}

class _HealthSection extends StatelessWidget {
  const _HealthSection({
    required this.title,
    required this.icon,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => FubaoCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: FubaoColors.mintStrong, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 90,
                  child: Text(rows[index].$1,
                      style: const TextStyle(
                          color: FubaoColors.inkMuted,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(rows[index].$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ]),
      );
}

class _HealthProfileEditDialog extends StatefulWidget {
  const _HealthProfileEditDialog({required this.initial});
  final Map<String, dynamic> initial;

  @override
  State<_HealthProfileEditDialog> createState() =>
      _HealthProfileEditDialogState();
}

class _HealthProfileEditDialogState extends State<_HealthProfileEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController conditionsController;
  late final TextEditingController medicationsController;
  late final TextEditingController medicalHistoryController;
  late final TextEditingController contactController;
  String? errorText;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
        text: widget.initial['relativeName']?.toString() ?? '');
    heightController = TextEditingController(
        text: widget.initial['heightCm']?.toString() ?? '');
    weightController = TextEditingController(
        text: widget.initial['weightKg']?.toString() ?? '');
    conditionsController = TextEditingController(
      text:
          (widget.initial['chronicConditions'] as List? ?? const []).join('、'),
    );
    medicationsController = TextEditingController(
      text: _historyText(widget.initial['medicationHistory']),
    );
    medicalHistoryController = TextEditingController(
      text: _historyText(widget.initial['medicalHistory']),
    );
    contactController = TextEditingController(
        text: widget.initial['emergencyContact']?.toString() ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    conditionsController.dispose();
    medicationsController.dispose();
    medicalHistoryController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('编辑健康档案'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '称呼'),
            ),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '身高（cm）'),
            ),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '体重（kg）'),
            ),
            TextField(
              controller: conditionsController,
              decoration: const InputDecoration(
                  labelText: '慢病类型', hintText: '多个项目用逗号分隔'),
            ),
            TextField(
              controller: medicationsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '用药史'),
            ),
            TextField(
              controller: medicalHistoryController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '既往病史'),
            ),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '紧急联系人'),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!,
                  style: const TextStyle(color: FubaoColors.orangeStrong)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(onPressed: _submit, child: const Text('保存')),
        ],
      );

  void _submit() {
    final name = nameController.text.trim();
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    if (name.isEmpty ||
        height == null ||
        height < 80 ||
        height > 250 ||
        weight == null ||
        weight < 20 ||
        weight > 300) {
      setState(() => errorText = '请填写称呼，以及有效的身高和体重。');
      return;
    }
    final conditions = conditionsController.text
        .split(RegExp(r'[,，、]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    Navigator.pop(context, {
      'relativeName': name,
      'heightCm': height,
      'weightKg': weight,
      'chronicConditions': conditions,
      'medicationHistory': medicationsController.text.trim().isEmpty
          ? <String, dynamic>{}
          : <String, dynamic>{
              'summary': medicationsController.text.trim(),
            },
      'medicalHistory': medicalHistoryController.text.trim().isEmpty
          ? <String, dynamic>{}
          : <String, dynamic>{
              'summary': medicalHistoryController.text.trim(),
            },
      if (contactController.text.trim().isNotEmpty)
        'emergencyContact': contactController.text.trim(),
    });
  }
}

String _historyText(Object? value) {
  if (value is Map) {
    return value.values
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => item.toString())
        .join('、');
  }
  return value?.toString() ?? '';
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('福豹隐私政策'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('更新日期：2026 年 7 月 18 日',
                style: TextStyle(color: FubaoColors.inkMuted)),
            SizedBox(height: 18),
            Text('我们处理哪些信息',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                '为完成登录、家庭绑定和健康管理功能，福豹会处理手机号、家庭关系、健康档案、每日任务、健康记录、设备状态、消息和必要的安全审计信息。'),
            SizedBox(height: 18),
            Text('如何保护和使用',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                '这些信息仅用于应用功能，不用于广告追踪，也不会出售。iOS 登录凭证和离线缓存保存在本机 Keychain，服务端使用 HTTPS、加密、角色鉴权、限流和审计保护数据。'),
            SizedBox(height: 18),
            Text('你的选择',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                '你可以导出数据、关闭通知或申请注销。退出登录不会删除数据；退出家庭组会解除家庭访问关系；注销申请将在 30 天后执行删除。'),
            SizedBox(height: 18),
            Text('健康免责声明',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('福豹提供健康管理与关怀提醒，不提供诊断和治疗，不能替代医生的专业建议。'),
          ],
        ),
      );
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('福豹用户服务协议'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('生效日期：2026 年 7 月 18 日',
                style: TextStyle(color: FubaoColors.inkMuted)),
            SizedBox(height: 18),
            Text('服务说明',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('福豹为家庭成员提供健康计划、记录、提醒、话题和设备管理工具。服务内容可能随版本更新，以应用内实际功能为准。'),
            SizedBox(height: 18),
            Text('账号与家庭关系',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                '用户应使用本人手机号登录并妥善保管验证码。家庭邀请码仅用于获得授权的家庭成员绑定，不得转发给无关人员。退出登录、退出家庭组和注销账号是不同操作。'),
            SizedBox(height: 18),
            Text('健康信息提示',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('福豹不提供医疗诊断、处方或急救服务。健康数据异常时应及时咨询医生；紧急情况请立即联系当地急救机构。'),
            SizedBox(height: 18),
            Text('用户责任',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('用户应确保录入信息真实、获得长辈授权并合理使用提醒功能，不得利用服务侵害他人权益或干扰系统安全。'),
          ],
        ),
      );
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
