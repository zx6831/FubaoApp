# 福豹软件 V1 完成度审计

更新日期：2026-07-18

本文按《福豹 App 后续开发路线图》的八个阶段记录可复核证据。代码完成不等同于已经上架；必须由外部账号或 Apple 工具完成的关卡单独列在末尾。

| 阶段 | 当前结论 | 可复核证据 |
| --- | --- | --- |
| 1. 数据架构与接口契约 | 已完成 | PostgreSQL/Prisma 模型与迁移、Redis、Docker Compose、统一响应/异常/校验/角色鉴权/限流、`/docs` OpenAPI；Flutter `demo/dev/production` 与异步仓库边界。 |
| 2. 登录与家庭绑定 | 已完成 | 手机验证码、JWT/Refresh Token/退出与恢复、30 分钟四位邀请码、1 子女 + 1 长辈服务端约束、Keychain 会话；认证与越权 E2E 测试。 |
| 3. 档案与模拟设备 | 已完成 | 首次引导、邀请接收、模拟发现/配网/在线/离线/激活、真实档案查看与编辑、音量/朗读/勿扰、解绑与退出家庭；onboarding E2E 与 Flutter 数据闭环测试。 |
| 4. 计划与每日任务 | 已完成 | 三步创建，七类计划，暂停/恢复/结束，时区生成任务，真实周/月统计与历史详情，完成/没做与幂等键，手动提醒；双端仓库与 E2E 测试。 |
| 5. 健康、火花与告警 | 已完成 | 血压/血糖/心情/体重确认记录、趋势入口、L1/L2 告警与 24 小时去重、告警消息与 APNs 适配器、处理/关闭、连续火花与历史；L3 保持禁用。 |
| 6. 话题、消息、设置与隐私 | 已完成 | 模板话题、复制事件、微信可用时打开微信/否则系统分享、四类消息、动态周报、双端真实设置、全局字体、iOS 原生朗读、服务协议/隐私政策、数据导出、反馈与 30 天注销执行器。 |
| 7. 离线、安全与部署 | 已完成（配置与本机可验证部分） | Keychain 密钥缓存、离线幂等重试、错误/同步状态、APNs/假通知适配器、审计、字段加密、限流、Caddy HTTPS、备份恢复与生产 Compose。 |
| 8. iOS 发布 | 源码与材料已完成；外部发布关卡待执行 | `cn.fubao.app`、1.0.0+1、App Icon/启动页、Privacy Manifest、推送 entitlement、商店文案、隐私政策和发布清单。 |

## 最新自动验证

- Flutter：`flutter analyze --no-pub` 无问题；64 项测试通过，包含双端流程、离线、真实设置/计划统计、无障碍偏好、390×844 Golden、360/390/430 宽度与 360px/140% 字号滚动检查；Web Debug 生产环境构建成功。
- API：Prisma schema 校验与 Client 生成成功；10 个测试套件、25 项测试通过；NestJS 构建成功。
- 隐私：测试覆盖预约注销、到期执行、旧 Access Token 失效，以及原手机号可重新注册。
- 静态发布文件：`Info.plist` XML 校验通过；生产 Compose 配置校验通过；源码无空 `onTap`/`onPressed` 回调。

## 不可替代的外部关卡

以下项目无法在 Windows 代码工作区内伪造完成，也不应被标记为已发布：

1. Apple Developer Team、证书、Provisioning Profile 和 App Store Connect 应用记录。
2. macOS/Xcode 上的 Archive、真实 iPhone 安装、通知权限与安全区验收。
3. 正式 HTTPS 域名、生产 PostgreSQL/Redis、短信供应商、APNs Key/JWT 与运营主体信息。
4. TestFlight 内/外部测试、真实设备商店截图、审核账号和 App Store 审核。

执行顺序与验收项见 `docs/ios-release-checklist.md`，部署和恢复步骤见 `docs/deployment-and-recovery.md`。
