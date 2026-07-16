# 福豹调试 API

NestJS 演示后端，用于联调家庭绑定、计划任务、火花、话题、健康关怀提醒和隐私操作。当前状态存储在内存中，重启后重置；生产部署前需替换为 PostgreSQL/Redis 持久化实现。

## 启动

```powershell
npm.cmd install
npm.cmd run start:dev
```

- API：`http://localhost:3000/api`
- OpenAPI：`http://localhost:3000/docs`
- 健康检查：`http://localhost:3000/api/health`

## 测试与构建

```powershell
npm.cmd test
npm.cmd run build
```

测试登录令牌为 `child-token` 和 `elder-token`，只能用于本地调试，不能进入生产环境。
