$ErrorActionPreference = "Stop"

$env:BRAVE_API_KEY = [Environment]::GetEnvironmentVariable("BRAVE_API_KEY", "User")
if ([string]::IsNullOrWhiteSpace($env:BRAVE_API_KEY)) { exit 20 }
$env:BRAVE_MCP_ENABLED_TOOLS = "brave_web_search brave_news_search brave_image_search brave_summarizer brave_llm_context"

& "{{NPMX_PATH}}" "-y" "@brave/brave-search-mcp-server@2.0.82" "--transport" "stdio"
exit $LASTEXITCODE
