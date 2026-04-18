# Codesome Codex Installer

One-click installer for Codex CLI configured to use Codesome, using the same principle as the SSS-style installer: custom provider + base URL + env key.

## What it does

- Installs `@openai/codex`
- Writes `~/.codex/config.toml`
- Writes a custom provider that points Codex at `https://cc.codesome.ai`
- Persists `CODESOME_API_KEY` into your shell config
- Points Codex at `https://cc.codesome.ai`

## Install

Use the published raw script directly:

```bash
CODEX_TOKEN="your_api_key" \
CODEX_API_URL="https://cc.codesome.ai" \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zenenznze/codesome-codex-installer/main/install-codex.sh)"
```

## Defaults

- `CODEX_API_URL=https://cc.codesome.ai`
- `CODEX_MODEL=gpt-5.4`
- `CODEX_REVIEW_MODEL=gpt-5.4`
- `CODEX_REASONING_EFFORT=xhigh`

## Notes

- The installer accepts `CODEX_TOKEN` and persists it as `CODESOME_API_KEY`
- It writes the key into `~/.bashrc` or `~/.zshrc`
- Existing Codex config and shell config are backed up before replacement
