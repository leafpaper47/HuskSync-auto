# 把本地的 "自动同步 + 自动构建" HuskSync 仓库推到你的 GitHub 仓库
# 用法：
#   .\push-to-github.ps1 -RepoUrl https://github.com/<你的用户名>/HuskSync-auto.git
#   .\push-to-github.ps1 -RepoUrl https://github.com/<你的用户名>/HuskSync-auto.git -Token ghp_xxx
#
# 说明：GitHub 的密码认证已停用，必须用 Personal Access Token。
#   classic token：勾选 repo
#   fine-grained token：对目标仓库给 Contents: Read and write

param(
    [Parameter(Mandatory = $true)][string]$RepoUrl,
    [string]$Token,
    [string]$Branch = 'master'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Test-Path '.git')) { throw '当前目录不是 git 仓库。' }

# 带 token 时把凭据塞进 remote（不写进 .git/config 明文，仅本次 push 使用）
$pushUrl = $RepoUrl
if ($Token) {
    $pushUrl = $RepoUrl -replace '^https://', "https://x-access-token:$Token@"
}

Write-Host "==> 设置 origin: $RepoUrl" -ForegroundColor Cyan
if (git remote | Select-String -Quiet '^origin$') { git remote set-url origin $RepoUrl }
else { git remote add origin $RepoUrl }

Write-Host "==> 推送到 $Branch" -ForegroundColor Cyan
git push $pushUrl "${Branch}:${Branch}"

if ($LASTEXITCODE -ne 0) { throw "push 失败（exit=$LASTEXITCODE）。请检查仓库地址与 token 权限。" }

Write-Host ''
Write-Host '推送完成。接下来：' -ForegroundColor Green
Write-Host '  1) 打开仓库 Actions 页面，点 "I understand my workflows, go ahead and enable them"（fork 仓库必须手动启用一次）'
Write-Host '  2) 手动运行一次 Sync upstream 与 Build，确认工作流正常'
Write-Host '  3) 之后 Releases 里的 auto-build 会一直是最新构建'
