$ErrorActionPreference = "Stop"

$env:PYTHONIOENCODING = "utf-8"
& "{{UVX_EXE}}" "mcp-server-fetch==2025.4.7"
exit $LASTEXITCODE
