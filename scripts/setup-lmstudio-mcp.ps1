[CmdletBinding()]
param(
  [string]$WslDistro = "Ubuntu-24.04",
  [string]$ResearchGatewayPath = "/home/$([Environment]::UserName)/projects/research-gateway",
  [string]$SkillRouterPath = "/home/$([Environment]::UserName)/work/repos/skill-router-gateway",
  [string]$SkillRouterConfig = "",
  [string]$ResearchGatewayUrl = "http://127.0.0.1:8765",
  [string]$LmStudioDir = "$env:USERPROFILE\\.lmstudio",
  [string]$TemplateRoot = "$PSScriptRoot\\..",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-CommandPath {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Required command '$Name' was not found in PATH." }
  return $cmd.Source
}

function Resolve-Tokenize {
  param([string]$Text, [hashtable]$Tokens)
  foreach ($key in $Tokens.Keys) {
    $Text = $Text.Replace($key, $Tokens[$key])
  }
  return $Text
}

function Write-TemplatedFile {
  param([string]$InputPath, [string]$OutputPath, [hashtable]$Tokens)
  $raw = Get-Content -Path $InputPath -Raw
  $rendered = Resolve-Tokenize -Text $raw -Tokens $Tokens
  if ($DryRun) { return }
  Set-Content -Path $OutputPath -Value $rendered -NoNewline -Encoding UTF8
}

function Write-TextIfChanged {
  param([string]$Path, [string]$Content)
  if ((Test-Path $Path) -and (Get-Content -Raw $Path) -eq $Content) {
    Write-Host "unchanged: $Path"
    return
  }
  Set-Content -Path $Path -Value $Content -NoNewline -Encoding UTF8
  Write-Host "updated:  $Path"
}

$root = Resolve-Path $TemplateRoot
$templateDir = Join-Path $root "templates"
$launchersDir = Join-Path $LmStudioDir "mcp-launchers"
$launcherOutDir = $launchersDir
$launcherPathForJson = $launcherOutDir.Replace('\', '\\')

$npx = Resolve-CommandPath "npx"
$uvx = Resolve-CommandPath "uvx"
$wsl = Resolve-CommandPath "wsl.exe"
$powershell = (Get-Command powershell.exe).Source
$powershellForJson = $powershell.Replace('\', '\\')

if ([string]::IsNullOrWhiteSpace($SkillRouterConfig)) {
  $SkillRouterConfig = Join-Path $SkillRouterPath "config.yaml"
}

$tokens = @{
  "{{NPMX_PATH}}" = $npx
  "{{UVX_EXE}}" = $uvx
  "{{WSL_EXE}}" = $wsl
  "{{WSL_DISTRO}}" = $WslDistro
  "{{RESEARCH_GATEWAY_PATH}}" = $ResearchGatewayPath
  "{{RESEARCH_GATEWAY_PYTHON}}" = "$ResearchGatewayPath/.venv/bin/python"
  "{{RESEARCH_GATEWAY_URL}}" = $ResearchGatewayUrl
  "{{SKILL_ROUTER_PATH}}" = $SkillRouterPath
  "{{SKILL_ROUTER_PYTHON}}" = "$SkillRouterPath/.venv/bin/python"
  "{{SKILL_ROUTER_CONFIG}}" = $SkillRouterConfig
  "{{BRAVE_LAUNCHER_PATH}}" = "${launcherPathForJson}\\brave-search.ps1"
  "{{FIRECRAWL_LAUNCHER_PATH}}" = "${launcherPathForJson}\\firecrawl.ps1"
  "{{FETCH_LAUNCHER_PATH}}" = "${launcherPathForJson}\\fetch.ps1"
  "{{RESEARCH_GATEWAY_LAUNCHER_PATH}}" = "${launcherPathForJson}\\research-gateway.ps1"
  "{{SKILL_ROUTER_LAUNCHER_PATH}}" = "${launcherPathForJson}\\skill-router.ps1"
  "{{POWERSHELL_EXE}}" = $powershellForJson
}

if ($DryRun) {
  Write-Host "DRY RUN: no files will be written."
}

if (-not (Test-Path $LmStudioDir)) { New-Item -ItemType Directory -Path $LmStudioDir -Force | Out-Null }
if (-not (Test-Path $launcherOutDir)) { New-Item -ItemType Directory -Path $launcherOutDir -Force | Out-Null }

Get-ChildItem -Path (Join-Path $templateDir "mcp-launchers") -File | ForEach-Object {
  $outPath = Join-Path $launcherOutDir $_.Name
  Write-TemplatedFile -InputPath $_.FullName -OutputPath $outPath -Tokens $tokens
  if (-not $DryRun) { Unblock-File -Path $outPath -ErrorAction SilentlyContinue; }
}

$mcpTemplatePath = Join-Path $templateDir "mcp.json.template"
$mcpTemplateContent = Get-Content -Raw -Path $mcpTemplatePath
$mcpRendered = Resolve-Tokenize -Text $mcpTemplateContent -Tokens $tokens
$mcpPath = Join-Path $LmStudioDir "mcp.json"

if (-not $DryRun) {
  if (Test-Path $mcpPath) {
    $backup = Join-Path $LmStudioDir ("mcp.json.bak-{0}" -f (Get-Date -Format "yyyyMMddTHHmmss"))
    Copy-Item -Path $mcpPath -Destination $backup -Force
    Write-Host "backed up: $mcpPath -> $backup"
  }
  Write-TextIfChanged -Path $mcpPath -Content $mcpRendered
}
else {
  Write-Host "Target mcp.json preview:"
  Write-Output $mcpRendered
}

Write-Host ""
Write-Host "LM Studio MCP setup generated."
Write-Host "Targets:"
Write-Host "  .lmstudio: $LmStudioDir"
Write-Host "  mcp-launchers: $launcherOutDir"
Write-Host "  mcp.json: $mcpPath"
Write-Host ""
Write-Host "Next:"
Write-Host "  1) Open LM Studio > Program > Integrations > MCP and verify listed servers."
Write-Host "  2) In WSL: start SearXNG + research gateway + skill-router services before chatting."
