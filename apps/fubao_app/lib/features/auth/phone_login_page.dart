import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({
    required this.onRequestCode,
    required this.onVerifyCode,
    this.errorMessage,
    this.testCode,
    super.key,
  });

  final Future<bool> Function(String phone) onRequestCode;
  final Future<bool> Function(String phone, String code, AppRole role) onVerifyCode;
  final String? errorMessage;
  final String? testCode;

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  AppRole _role = AppRole.child;
  bool _codeRequested = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      _show('请输入正确的 11 位手机号');
      return;
    }
    setState(() => _busy = true);
    final success = _codeRequested
        ? await widget.onVerifyCode(phone, _codeController.text.trim(), _role)
        : await widget.onRequestCode(phone);
    if (mounted) {
      setState(() {
        _busy = false;
        if (success) _codeRequested = true;
      });
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(large: true),
                  const SizedBox(height: 36),
                  Text('手机号登录', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('先选择身份，再用验证码安全登录。', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  SegmentedButton<AppRole>(
                    segments: const [
                      ButtonSegment(value: AppRole.child, label: Text('我是子女'), icon: Icon(Icons.favorite_rounded)),
                      ButtonSegment(value: AppRole.elder, label: Text('我是长辈'), icon: Icon(Icons.wb_sunny_rounded)),
                    ],
                    selected: {_role},
                    onSelectionChanged: _codeRequested ? null : (value) => setState(() => _role = value.first),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    key: const Key('phoneField'),
                    controller: _phoneController,
                    enabled: !_codeRequested,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    decoration: const InputDecoration(labelText: '手机号', prefixText: '+86  ', border: OutlineInputBorder()),
                  ),
                  if (_codeRequested) ...[
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('codeField'),
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: '验证码', border: OutlineInputBorder()),
                    ),
                    if (widget.testCode != null)
                      Text('调试验证码：${widget.testCode}', style: const TextStyle(color: FubaoColors.mintStrong)),
                  ],
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(widget.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('loginSubmit'),
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    child: Text(_busy ? '请稍候…' : (_codeRequested ? '登录' : '获取验证码')),
                  ),
                  if (_codeRequested)
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _codeRequested = false),
                      child: const Text('更换手机号或身份'),
                    ),
                  const SizedBox(height: 24),
                  const SafetyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
