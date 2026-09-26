# LM Studio MCP Plug-and-Play Bundle

This folder contains everything needed to configure LM Studio MCP integrations on a fresh machine without copying hard-coded local paths or secrets.

It assumes you already have these service repos checked out on the target machine:

- `research-gateway` (WSL path, default: `/home/$USER/projects/research-gateway`)
- `skill-router-gateway` (WSL path, default: `/home/$USER/work/repos/skill-router-gateway`)

It configures:

- `brave-search` MCP via `@brave/brave-search-mcp-server`
- `firecrawl` MCP via `firecrawl-mcp`
- `fetch` MCP via `mcp-server-fetch`
- `research-gateway` MCP (wrapper that points to WSL gateway)
- `skill-router` MCP (wrapper that points to WSL skill router)

## Files in this folder

- `templates/mcp.json.template`  
  LM Studio `mcp.json` template with placeholders.
- `templates/mcp-launchers/*`  
  Launchers for Brave, Firecrawl, fetch, research-gateway, and skill-router.
- `scripts/setup-lmstudio-mcp.ps1`  
  One-time setup script that writes launchers and `mcp.json`.
- `scripts/check-lmstudio-mcp.ps1`  
  Simple local health check script.

## 1) Prepare WSL repos

On each target machine, set up both repos and install dependencies:

```bash
# inside WSL, for research gateway
cd /home/<you>/projects/research-gateway
cp .env.example .env   # fill BRAVE_API_KEY and FIRECRAWL_API_KEY here
uv sync
./scripts/start_gateway.sh  # optional manual startup; the MCP launcher starts it when needed

# inside WSL, for skill-router gateway
cd /home/<you>/work/repos/skill-router-gateway
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
cp config.yaml.example config.yaml   # tweak if needed
```

For research-gateway, start any required services you use (for example `docker compose up -d searxng`).

The MCP launcher starts the research gateway HTTP service when needed and keeps startup text off MCP stdout. To keep the MCP connection available when that service cannot start, use a `research-gateway` checkout with the bridge resilience fix as well. The service repo must be updated separately; this bundle does not contain its source.

## 2) Install Windows-side LM Studio MCP files

Run PowerShell from the target machine:

```powershell
cd <this-folder>
./scripts/setup-lmstudio-mcp.ps1 `
  -WslDistro "Ubuntu-24.04" `
  -ResearchGatewayPath "/home/<you>/projects/research-gateway" `
  -SkillRouterPath "/home/<you>/work/repos/skill-router-gateway"
```

Optional overrides:

- `-ResearchGatewayUrl "http://127.0.0.1:8765"`
- `-SkillRouterConfig "/home/<you>/work/repos/skill-router-gateway/config.yaml"`
- `-LmStudioDir "C:\Users\<you>\.lmstudio"`
- `-DryRun` to preview file output only.

This script:

- creates/updates `C:\Users\<you>\.lmstudio\mcp-launchers\*`
- writes `C:\Users\<you>\.lmstudio\mcp.json` from template
- creates a backup of existing `mcp.json` if present

## 3) Verify

```powershell
./scripts/check-lmstudio-mcp.ps1
```

Also verify in LM Studio:

- Program → Integrations → MCP
- `brave-search`, `firecrawl`, `fetch`, `research-gateway`, `skill-router` appear enabled

Then confirm one request path in LM Studio chat:

- research: run a simple search via the `research-gateway` MCP tools
- routing: call one non-sensitive skill path to confirm `route_task_to_skills` from `skill-router` is available

## What must be pushed to GitHub

Push this bundle as-is.

Also ensure these repos are pushed:

- `research-gateway` repo (source + scripts + `.env.example`)
- `skill-router-gateway` repo (source + `config.yaml.example`, scripts/requirements)

Keep these out of git:

- `.env` files and API keys (keep `.env.example` for shared defaults)
- `.venv` directories
- LM Studio local cache/runtime directories (`.lmstudio`)
- any machine-specific absolute path overrides in generated `mcp.json`/launchers

### Why this works cross-machine

- The repository contains only portable templates and install scripts.
- Runtime paths are injected at setup time (`-ResearchGatewayPath`, `-SkillRouterPath`, `-LmStudioDir`, `-WslDistro`).
- API keys are read from local Windows user env vars (`BRAVE_API_KEY`, `FIRECRAWL_API_KEY`) when launching MCP.

### Recommended git settings before committing

- Keep `output/`, `.venv/`, `*.log`, `.env*` (except `.env.example`), and any `**/.lmstudio` paths in `.gitignore`.
- Never store machine-specific files with absolute paths (for example `C:\Users\<you>\...`) in tracked JSON/PS1 files.
