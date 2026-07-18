# 福豹 iOS / TestFlight / App Store 发布清单

## 已在代码仓库准备

- `cn.fubao.app`、版本 `1.0.0+1`、仅 iPhone 竖屏。
- 完整不透明 App Icon 尺寸集、品牌启动图、中文显示名。
- `PrivacyInfo.xcprivacy`、Keychain 安全存储、推送 entitlement、APNs 权限与 Token 注册。
- production 环境强制 HTTPS；Release 构建通过 Web 等价检查。
- 隐私政策与商店元数据草案、审核路径和模拟设备说明。

## 必须在 macOS/Xcode 完成

1. 安装与仓库 Flutter 版本兼容的 Xcode，登录 Apple Developer 团队。
2. 在 Apple Developer 后台创建 App ID `cn.fubao.app`，启用 Push Notifications；在 App Store Connect 创建“福豹”。
3. 打开 `apps/fubao_app/ios/Runner.xcworkspace`，选择正确 Team，确认 Signing & Capabilities 中 Push Notifications 可用。
4. 在仓库执行：

   ```bash
   cd apps/fubao_app
   flutter clean
   flutter pub get
   flutter test
   flutter analyze
   flutter build ipa --release \
     --dart-define=APP_ENV=production \
     --dart-define=API_BASE_URL=https://正式域名/api
   ```

5. 在至少一台真实 iPhone 上验证冷启动、登录、家庭绑定、键盘、安全区、通知授权、前后台切换、断网同步、注销和退出家庭组。
6. 用 Xcode Organizer 上传 Archive，等待自动处理后分发到 TestFlight 内部测试。
7. 使用子女和长辈两台设备完成端到端 TestFlight 测试；通过后邀请外部测试。
8. 上传 iPhone 6.9 英寸和 6.5 英寸截图，填写 `app-store-listing.md` 中的元数据、支持网址、隐私政策网址和审核账号。
9. 完成 App Privacy 问卷：健康与健身、手机号、用户 ID、用户内容均与身份关联，用于 App 功能，不用于追踪；不出售数据。
10. 确认实际运营主体、隐私邮箱、短信/云/APNs 服务商和备案合规信息后再提交审核。

## TestFlight 验收

- 首次安装与升级安装都可启动，无白屏。
- 子女/长辈登录、30 分钟邀请码、健康档案和模拟设备激活通过。
- 子女建计划 → 长辈完成 → 子女 10 秒内看到进度 → 火花/话题更新。
- 推送拒绝和允许两条路径均可用；拒绝不会阻塞主流程。
- 弱网操作只同步一次；Token 过期回到登录页；退出登录与退出家庭组行为不同。
- 数据导出、30 天注销申请、隐私政策入口和健康免责声明可访问。

## 外部发布门槛

以下内容不应在缺失时提交审核：Apple Developer Team、正式 HTTPS API、短信供应商、APNs Key/JWT、公开隐私政策网址、支持联系方式、审核手机号与验证码、真实 iPhone 截图。
