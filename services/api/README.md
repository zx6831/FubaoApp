# 福豹调试 API

NestJS 可部署后端，已接入 PostgreSQL、Prisma、Redis、统一响应格式、参数校验、限流与 OpenAPI。认证和家庭绑定使用持久化数据；尚未完成的业务模块仍保留演示实现。

## 启动

```powershell
npm.cmd install
npm.cmd run prisma:migrate
npm.cmd run start:dev
```

- API：`http://localhost:3000/api`
- OpenAPI：`http://localhost:3000/docs`
- 健康检查：`http://localhost:3000/api/health`

## 测试与构建

```powershell
npm.cmd run verify
```

开发与测试环境验证码固定为 `2468`。接口支持 15 分钟访问令牌、30 天刷新令牌轮换、退出撤销、角色鉴权，以及 30 分钟有效的一次性 4 位家庭邀请码。

根目录执行 `docker compose up -d --build` 可一次启动 API、PostgreSQL 和 Redis。生产环境必须替换 `.env.example` 中的三个安全密钥。
