$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupDirectory = Join-Path $root 'backups'
New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$target = "/backups/fubao-$stamp.dump"
docker compose --env-file .env.production -f docker-compose.production.yml exec -T postgres `
  pg_dump -U fubao -d fubao -Fc -f $target
Write-Host "Backup created: backups/fubao-$stamp.dump"
