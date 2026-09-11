$ErrorActionPreference = "Stop"

$env:FIRECRAWL_API_KEY = [Environment]::GetEnvironmentVariable("FIRECRAWL_API_KEY", "User")
if ([string]::IsNullOrWhiteSpace($env:FIRECRAWL_API_KEY)) { exit 20 }

& "{{NPMX_PATH}}" "-y" "firecrawl-mcp@3.20.2"
exit $LASTEXITCODE
