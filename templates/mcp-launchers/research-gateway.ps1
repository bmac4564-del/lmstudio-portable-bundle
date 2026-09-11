$ErrorActionPreference = "Stop"

& "{{WSL_EXE}}" "-d" "{{WSL_DISTRO}}" "--" "bash" "-lc" "cd {{RESEARCH_GATEWAY_PATH}} && exec {{RESEARCH_GATEWAY_PYTHON}} -m research_gateway.mcp_server"
exit $LASTEXITCODE
