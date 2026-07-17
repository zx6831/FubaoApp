param([Parameter(Mandatory = $true)][string]$BackupFile)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$resolved = Resolve-Path $BackupFile
if (-not $resolved.Path.StartsWith((Join-Path $root 'backups'))) {
  throw 'Backup file must be inside the repository backups directory.'
}
$containerPath = "/backups/$($resolved.Path | Split-Path -Leaf)"
docker compose --env-file .env.production -f docker-compose.production.yml exec -T postgres `
  pg_restore -U fubao -d fubao --clean --if-exists $containerPath
Write-Host 'Restore completed. Run API health and smoke tests before reopening traffic.'
