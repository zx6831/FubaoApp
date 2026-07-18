import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.role,
    required this.profileComplete,
    required this.deviceActive,
    required this.onSaveProfile,
    required this.onDiscoverDevice,
    required this.onActivateDevice,
    required this.onRefresh,
    required this.onLogout,
    this.discoveredDeviceSerial,
    this.errorMessage,
    super.key,
  });

  final AppRole role;
  final bool profileComplete;
  final bool deviceActive;
  final String? discoveredDeviceSerial;
  final String? errorMessage;
  final Future<bool> Function({
    required String relativeName,
    required double? heightCm,
    required double? weightKg,
    required List<String> chronicConditions,
    required String medicationHistory,
    required String medicalHistory,
    required String emergencyContact,
  }) onSaveProfile;
  final Future<bool> Function() onDiscoverDevice;
  final Future<bool> Function(String networkName) onActivateDevice;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _relativeName = TextEditingController(text: '妈妈');
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _conditions = TextEditingController(text: '高血压');
  final _medications = TextEditingController();
  final _medicalHistory = TextEditingController();
  final _emergency = TextEditingController();
  final _network = TextEditingController(text: '家庭 Wi-Fi');
  bool _consent = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _relativeName,
      _height,
      _weight,
      _conditions,
      _medications,
      _medicalHistory,
      _emergency,
      _network
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == AppRole.elder) return _elderWaiting(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(large: true),
                  const SizedBox(height: 26),
                  Text('完成家庭设置',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('建立健康档案并激活福豹设备后，即可进入主页。',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  _stepHeader(1, '长辈健康档案', widget.profileComplete),
                  if (!widget.profileComplete) ..._profileFields(),
                  const SizedBox(height: 24),
                  _stepHeader(2, '模拟设备激活', widget.deviceActive),
                  if (widget.profileComplete && !widget.deviceActive)
                    ..._deviceFields(),
                  if (widget.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(widget.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  TextButton(
                      onPressed: _busy ? null : widget.onLogout,
                      child: const Text('退出登录')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _profileFields() => [
        const SizedBox(height: 14),
        TextField(
            controller: _relativeName,
            decoration: const InputDecoration(
                labelText: '称呼', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '身高 cm', border: OutlineInputBorder()))),
          const SizedBox(width: 12),
          Expanded(
              child: TextField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '体重 kg', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: _conditions,
            decoration: const InputDecoration(
                labelText: '慢病类型（用逗号分隔）', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
            controller: _medications,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: '用药史',
                hintText: '例如：氨氯地平，每日一次',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
            controller: _medicalHistory,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: '既往病史',
                hintText: '例如：2022 年住院治疗心脏病',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
            controller: _emergency,
            decoration: const InputDecoration(
                labelText: '紧急联系人', border: OutlineInputBorder())),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _consent,
          onChanged: _busy
              ? null
              : (value) => setState(() => _consent = value ?? false),
          title: const Text('已获得长辈授权，同意建立健康档案'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        FilledButton(
          onPressed: _busy || !_consent
              ? null
              : () => _run(() async {
                    await widget.onSaveProfile(
                      relativeName: _relativeName.text.trim(),
                      heightCm: double.tryParse(_height.text.trim()),
                      weightKg: double.tryParse(_weight.text.trim()),
                      chronicConditions: _conditions.text
                          .split(RegExp('[,，]'))
                          .map((value) => value.trim())
                          .where((value) => value.isNotEmpty)
                          .toList(),
                      medicationHistory: _medications.text.trim(),
                      medicalHistory: _medicalHistory.text.trim(),
                      emergencyContact: _emergency.text.trim(),
                    );
                  }),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: const Text('保存健康档案'),
        ),
      ];

  List<Widget> _deviceFields() => [
        const SizedBox(height: 14),
        if (widget.discoveredDeviceSerial == null)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async => widget.onDiscoverDevice()),
            icon: const Icon(Icons.radar_rounded),
            label: const Text('发现附近的模拟设备'),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: FubaoColors.mintSoft,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.memory_rounded, color: FubaoColors.mintStrong),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('福豹家庭智能体\n${widget.discoveredDeviceSerial}')),
              const Text('已发现', style: TextStyle(color: FubaoColors.mintDeep)),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _network,
              decoration: const InputDecoration(
                  labelText: '家庭网络名称', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                    () async => widget.onActivateDevice(_network.text.trim())),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: const Text('模拟配网并激活'),
          ),
        ],
      ];

  Widget _stepHeader(int number, String title, bool complete) => Row(children: [
        CircleAvatar(
          backgroundColor:
              complete ? FubaoColors.mintStrong : FubaoColors.orangeSoft,
          foregroundColor: complete ? Colors.white : FubaoColors.orangeStrong,
          child: complete ? const Icon(Icons.check_rounded) : Text('$number'),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ]);

  Widget _elderWaiting(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandMark(large: true),
                const SizedBox(height: 34),
                const Icon(Icons.family_restroom_rounded,
                    size: 82, color: FubaoColors.mintStrong),
                const SizedBox(height: 20),
                Text('家庭正在设置中',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 10),
                const Text('请等待子女端完成健康档案和设备激活。'),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _busy ? null : () => _run(widget.onRefresh),
                    child: const Text('刷新状态')),
                TextButton(
                    onPressed: _busy ? null : widget.onLogout,
                    child: const Text('退出登录')),
              ]),
            ),
          ),
        ),
      );
}
