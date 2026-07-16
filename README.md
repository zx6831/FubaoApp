# 福豹 App

福豹慢病共管家庭智能体的 Flutter 双角色客户端。

## 快速开始

客户端位于 `apps/fubao_app`，包含 iOS、Web 和 Windows 工程。当前 Windows 原生 C++ 工具链在本机自检阶段阻塞，因此推荐先用 Web 调试目标：

```powershell
cd apps\fubao_app
flutter pub get
flutter test
flutter run -d chrome
```

选择“我是子女”或“我是长辈”即可体验完整的四 Tab 页面和任务联动。

详细调试说明见 `apps/fubao_app/README.md`。
