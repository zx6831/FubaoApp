# 福豹 App

福豹慢病共管家庭智能体的 Flutter 双角色客户端与 NestJS 调试后端。

## 快速开始

客户端位于 `apps/fubao_app`，包含 iOS、Web 和 Windows 工程。当前 Windows 原生 C++ 工具链在本机自检阶段阻塞，因此推荐先用 Web 调试目标：

```powershell
cd apps\fubao_app
flutter pub get
flutter test
flutter run -d chrome
```

选择“我是子女”或“我是长辈”即可体验完整的四 Tab 页面和任务联动。

## 后端调试

后端位于 `services/api`，提供家庭绑定、计划任务、健康关怀提醒和隐私操作接口：

```powershell
cd services\api
npm.cmd install
npm.cmd run start:dev
```

启动后访问 `http://localhost:3000/docs` 查看并调试全部接口。也可以在仓库根目录运行 `docker compose up --build`。

当前客户端使用本地演示数据仓库，便于在没有账号、短信和云数据库时完整演示双端流程；后端可独立联调，下一阶段再接入正式认证、PostgreSQL/Redis 和客户端网络层。

详细说明见 `apps/fubao_app/README.md` 和 `services/api/README.md`。
