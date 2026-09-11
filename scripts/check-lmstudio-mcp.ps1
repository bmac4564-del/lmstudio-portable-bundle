[CmdletBinding()]
param(
  [string]$ResearchGatewayHealth = "http://127.0.0.1:8765/health",
  [string]$SkillRouterHealth = "http://127.0.0.1:8080/health",
  [string]$LmStudioDir = "$env:USERPROFILE\\.lmstudio"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-HttpJson {
  param([string]$Url)
  try {
    $resp = Invoke-RestMethod -Uri $Url -TimeoutSec 5
    return @($true, $resp)
  }
  catch {
    return @($false, $_.Exception.Message)
  }
}

Write-Host "LM Studio MCP path: $LmStudioDir"
if (-not (Test-Path $LmStudioDir)) {
  Write-Warning "LM Studio directory missing: $LmStudioDir"
  exit 1
}

$mcpJson = Join-Path $LmStudioDir "mcp.json"
if (Test-Path $mcpJson) {
  Write-Host "Found mcp.json"
} else {
  Write-Warning "Missing mcp.json"
}

$launchers = @("brave-search.ps1","firecrawl.ps1","fetch.ps1","research-gateway.ps1","skill-router.ps1")
foreach ($name in $launchers) {
  if (Test-Path (Join-Path $LmStudioDir ("mcp-launchers\\{0}" -f $name))) {
    Write-Host "Launcher present: $name"
  } else {
    Write-Warning "Launcher missing: $name"
  }
}

$checks = @(
  @{ Url = $ResearchGatewayHealth; Name = "research-gateway" },
  @{ Url = $SkillRouterHealth; Name = "skill-router" }
)

foreach ($c in $checks) {
  $result = Test-HttpJson -Url $c.Url
  if ($result[0]) {
    Write-Host "$($c.Name) is reachable: $($c.Url)"
  } else {
    Write-Warning "$($c.Name) unreachable: $($c.Url) ($($result[1]))"
  }
}
