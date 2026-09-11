$ErrorActionPreference = "Stop"

& "{{WSL_EXE}}" "-d" "{{WSL_DISTRO}}" "--" "bash" "-lc" "cd {{SKILL_ROUTER_PATH}} && exec {{SKILL_ROUTER_PYTHON}} -m skill_router_gateway.mcp_server --config {{SKILL_ROUTER_CONFIG}}"
exit $LASTEXITCODE
