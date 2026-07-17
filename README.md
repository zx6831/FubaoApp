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

默认是 `demo` 环境，选择“我是子女”或“我是长辈”即可体验完整的四 Tab 页面和任务联动。

## 后端调试

后端使用 PostgreSQL、Redis 和可重复执行的 Prisma 迁移。推荐在仓库根目录启动：

```powershell
docker compose up -d --build
```

启动后访问 `http://localhost:3000/docs` 查看接口。用真实登录流程调试 Flutter：

```powershell
cd apps\fubao_app
flutter run -d chrome --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

开发环境验证码固定为 `2468`。访问令牌、刷新令牌、家庭与邀请码均走真实后端；业务主页数据暂继续使用演示仓库，后续阶段逐项替换。

详细说明见 `apps/fubao_app/README.md` 和 `services/api/README.md`。
