$ErrorActionPreference = "Stop"

& "{{WSL_EXE}}" "-d" "{{WSL_DISTRO}}" "--" "bash" "-lc" "cd {{RESEARCH_GATEWAY_PATH}} && { ./scripts/start_gateway.sh >&2 || true; } && exec .venv/bin/python -m research_gateway.mcp_server"
exit $LASTEXITCODE
