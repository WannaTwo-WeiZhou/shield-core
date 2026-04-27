param(
	[Parameter(Mandatory = $true)]
	[string]$Title,
	[Parameter(Mandatory = $true)]
	[string]$BodyPath,
	[string]$Owner = "",
	[string]$Repo = "",
	[string[]]$Labels = @(),
	[switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubToken {
	if ($env:GH_TOKEN) {
		return $env:GH_TOKEN
	}
	if ($env:GITHUB_TOKEN) {
		return $env:GITHUB_TOKEN
	}
	throw "缺少 GitHub token。请先设置 GH_TOKEN 或 GITHUB_TOKEN。"
}

function Resolve-RepoFromOrigin {
	param(
		[string]$OwnerArg,
		[string]$RepoArg
	)

	if ($OwnerArg -and $RepoArg) {
		return @{
			Owner = $OwnerArg
			Repo = $RepoArg
		}
	}

	$remoteUrl = (git remote get-url origin).Trim()
	if (-not $remoteUrl) {
		throw "无法从 git remote origin 推断仓库，请显式传入 -Owner 和 -Repo。"
	}

	$patterns = @(
		"^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$",
		"^git@github\.com:(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$"
	)
	foreach ($pattern in $patterns) {
		if ($remoteUrl -match $pattern) {
			return @{
				Owner = $Matches.owner
				Repo = $Matches.repo
			}
		}
	}

	throw "暂不支持的 origin URL 格式: $remoteUrl"
}

if (-not (Test-Path -LiteralPath $BodyPath)) {
	throw "Issue 正文文件不存在: $BodyPath"
}

$body = Get-Content -LiteralPath $BodyPath -Raw
if (-not $body.Trim()) {
	throw "Issue 正文为空: $BodyPath"
}

$resolvedRepo = Resolve-RepoFromOrigin -OwnerArg $Owner -RepoArg $Repo
$payload = [ordered]@{
	title = $Title
	body = $body
}

if ($Labels.Count -gt 0) {
	$payload.labels = $Labels
}

if ($DryRun) {
	[ordered]@{
		endpoint = "https://api.github.com/repos/$($resolvedRepo.Owner)/$($resolvedRepo.Repo)/issues"
		payload = $payload
	} | ConvertTo-Json -Depth 10
	exit 0
}

$token = Get-GitHubToken
$headers = @{
	Authorization = "Bearer $token"
	Accept = "application/vnd.github+json"
	"X-GitHub-Api-Version" = "2022-11-28"
	"User-Agent" = "shield-core-ability-issue-script"
}

$response = Invoke-RestMethod `
	-Method Post `
	-Uri "https://api.github.com/repos/$($resolvedRepo.Owner)/$($resolvedRepo.Repo)/issues" `
	-Headers $headers `
	-ContentType "application/json; charset=utf-8" `
	-Body ($payload | ConvertTo-Json -Depth 10)

Write-Host ("已创建 Issue #{0}: {1}" -f $response.number, $response.html_url)
