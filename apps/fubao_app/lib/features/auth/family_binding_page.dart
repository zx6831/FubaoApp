import 'package:flutter/material.dart';

import '../../design/fubao_colors.dart';
import '../../domain/models.dart';
import '../../widgets/fubao_widgets.dart';

class FamilyBindingPage extends StatefulWidget {
  const FamilyBindingPage({
    required this.role,
    required this.onCreateInvitation,
    required this.onJoin,
    required this.onRefresh,
    required this.onLogout,
    this.invitationCode,
    this.errorMessage,
    super.key,
  });

  final AppRole role;
  final Future<bool> Function() onCreateInvitation;
  final Future<bool> Function(String code) onJoin;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;
  final String? invitationCode;
  final String? errorMessage;

  @override
  State<FamilyBindingPage> createState() => _FamilyBindingPageState();
}

class _FamilyBindingPageState extends State<FamilyBindingPage> {
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isChild = widget.role == AppRole.child;
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
                  const SizedBox(height: 34),
                  Text(isChild ? '邀请长辈加入家庭' : '加入家庭',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    isChild
                        ? '生成一个 30 分钟有效的邀请码，请长辈在自己的手机上输入。'
                        : '输入子女端生成的 4 位邀请码。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  if (isChild && widget.invitationCode != null)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                          color: FubaoColors.mintSoft,
                          borderRadius: BorderRadius.circular(28)),
                      child: Column(
                        children: [
                          const Text('家庭邀请码'),
                          const SizedBox(height: 8),
                          Text(widget.invitationCode!,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      color: FubaoColors.mintStrong,
                                      letterSpacing: 10)),
                          const Text('30 分钟内有效，仅可使用一次'),
                        ],
                      ),
                    ),
                  if (!isChild)
                    TextField(
                      key: const Key('invitationCodeField'),
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(letterSpacing: 12),
                      decoration: const InputDecoration(
                          labelText: '4 位邀请码', border: OutlineInputBorder()),
                    ),
                  if (widget.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(widget.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              if (isChild) {
                                await widget.onCreateInvitation();
                              } else {
                                await widget
                                    .onJoin(_codeController.text.trim());
                              }
                            }),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    child: Text(_busy
                        ? '请稍候…'
                        : (isChild
                            ? (widget.invitationCode == null
                                ? '创建家庭并生成邀请码'
                                : '重新生成邀请码')
                            : '确认加入')),
                  ),
                  if (isChild && widget.invitationCode != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        onPressed: _busy ? null : () => _run(widget.onRefresh),
                        child: const Text('长辈已加入，刷新状态')),
                  ],
                  const SizedBox(height: 8),
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
}
