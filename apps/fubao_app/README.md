# 福豹 Flutter App

这是按已确认效果图实现的可交互双角色 App。页面全部由 Flutter 组件绘制，`demo_images/` 只作为视觉参照。

## 当前可调试能力

- `demo` 环境登录前选择子女端或长辈端。
- `dev/production` 环境支持手机号验证码、登录恢复、令牌自动轮换和家庭邀请码绑定。
- iOS 会话通过原生 Keychain 保存；Chrome 调试使用当前浏览器进程内会话，不写入普通配置文件。
- 子女端：首页、计划、话题、我的；可创建计划、复制话术、切换角色。
- 长辈端：首页、计划、话题、我的；可完成任务、解锁话题、切换角色。
- 同一演示仓库维护任务状态，双端切换后可看到相同进度。
- 健康场景文案明确为关怀提醒，不作诊断或治疗建议。

## 本地运行

```powershell
cd apps\fubao_app
flutter pub get
flutter test
flutter run -d chrome
```

连接本地 API：

```powershell
flutter run -d chrome --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

开发环境验证码为 `2468`。生产环境必须传入 HTTPS 地址。

若本机 Visual Studio C++ 工具链配置完整，也可用 `flutter run -d windows` 调试桌面版。

如需 iOS 真机调试，请在 macOS 安装 Xcode 后执行：

```bash
flutter pub get
open ios/Runner.xcworkspace
```

选择开发团队和 Bundle Identifier 后从 Xcode 启动，或使用 `flutter run -d <iPhone设备ID>`。
