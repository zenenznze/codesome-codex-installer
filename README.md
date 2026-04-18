# Codesome Codex Installer

One-click installer for Codex CLI configured to use Codesome, using the same principle as the SSS-style installer: custom provider + base URL + env key.

## What it does

- Installs `@openai/codex`
- Writes `~/.codex/config.toml`
- Writes a custom provider that points Codex at `https://cc.codesome.ai`
- Persists `OPENAI_API_KEY` into your shell config
- Points Codex at `https://cc.codesome.ai`

## Install

Replace `RAW_URL` with the raw GitHub URL of `install-codex.sh`.

```bash
CODEX_TOKEN="your_api_key" \
bash -c "$(curl -fsSL RAW_URL)"
```

## Defaults

- `CODEX_API_URL=https://cc.codesome.ai`
- `CODEX_MODEL=gpt-5.4`
- `CODEX_REVIEW_MODEL=gpt-5.4`
- `CODEX_REASONING_EFFORT=xhigh`

## Notes

- The installer accepts `CODEX_TOKEN` and persists it as `OPENAI_API_KEY`
- It writes the key into `~/.bashrc` or `~/.zshrc`
- Existing Codex config is backed up before replacement
