# 福豹 V1 部署、监控与恢复

## 生产部署

1. 将 `.env.production.example` 复制为 `.env.production`，用密码管理器生成所有密钥；不得提交该文件。
2. 将 `FUBAO_DOMAIN` 指向服务器，开放 80/443 端口。
3. 运行 `docker compose --env-file .env.production -f docker-compose.production.yml up -d --build`。
4. Caddy 自动申请 HTTPS 证书；API 只通过反向代理暴露，PostgreSQL 和 Redis 不映射公网端口。
5. 运行 `curl https://$FUBAO_DOMAIN/api/health`，再执行登录、家庭绑定、任务完成与注销冒烟测试。

生产环境会拒绝短于 32 字符的 JWT、哈希 Pepper 和数据加密密钥。手机号、紧急联系人等可识别字段使用 AES-256-GCM 应用层加密；数据库卷还应启用云盘加密。

## 监控

- Docker 每 30 秒探测 `/api/health`，Caddy 输出 JSON 访问日志。
- 建议采集容器重启次数、HTTP 5xx、P95 延迟、PostgreSQL 连接数、Redis 内存和磁盘余量。
- 告警阈值：连续 3 次健康检查失败、5xx 超过 2%、磁盘超过 80%、备份超过 26 小时未成功。
- 所有写请求记录不包含请求正文的审计事件，避免把健康数据写入普通日志。

## 备份与恢复

- 每日由计划任务执行 `deploy/backup.ps1`，备份文件保存到 `backups/`，再同步到加密的异地对象存储。
- 建议保留 7 份日备、4 份周备和 6 份月备，并定期轮换加密密钥。
- 恢复前停止 API 写流量，执行 `deploy/restore.ps1 -BackupFile backups/<file>.dump`，随后运行数据库迁移、健康检查和核心冒烟测试。
- 每季度至少进行一次独立环境恢复演练并记录 RPO/RTO；目标 RPO 24 小时、RTO 4 小时。

## APNs

开发与测试默认 `APNS_MODE=fake`，消息只进入内存适配器。生产切换为 `apns` 前，配置 Bundle Topic 与短期 APNs JWT；密钥和 Token 只通过部署密钥系统注入，不进入镜像或 Git。
