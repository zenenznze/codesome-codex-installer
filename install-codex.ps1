$ErrorActionPreference = "Stop"

$Token = if ($env:CODEX_TOKEN) { $env:CODEX_TOKEN } elseif ($env:CODESOME_API_KEY) { $env:CODESOME_API_KEY } elseif ($env:OPENAI_API_KEY) { $env:OPENAI_API_KEY } else { "" }
$BaseUrl = if ($env:CODEX_API_URL) { $env:CODEX_API_URL } else { "https://cc.codesome.ai" }
$Model = if ($env:CODEX_MODEL) { $env:CODEX_MODEL } else { "gpt-5.4" }
$ReviewModel = if ($env:CODEX_REVIEW_MODEL) { $env:CODEX_REVIEW_MODEL } else { "gpt-5.4" }
$ReasoningEffort = if ($env:CODEX_REASONING_EFFORT) { $env:CODEX_REASONING_EFFORT } else { "xhigh" }
$CodexDir = Join-Path $env:USERPROFILE ".codex"
$ConfigFile = Join-Path $CodexDir "config.toml"

function Write-Step($Message) {
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success($Message) {
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-WarningLine($Message) {
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Info($Message) {
    Write-Host "[i] $Message" -ForegroundColor Blue
}

function Backup-File($Path) {
    if (Test-Path $Path) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BackupPath = "$Path.backup.$Timestamp"
        Copy-Item $Path $BackupPath -Force
        Write-Info "Backed up existing file: $BackupPath"
    }
}

function Ensure-Command($Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-NodeAndNpm {
    if (Ensure-Command "node" -and Ensure-Command "npm") {
        Write-Success "Node.js detected: $(node --version)"
        Write-Success "npm detected: $(npm --version)"
        return
    }

    Write-Step "Node.js/npm not found. Attempting winget installation..."
    if (-not (Ensure-Command "winget")) {
        throw "Node.js/npm not found and winget is unavailable. Install Node.js first from https://nodejs.org/en/download"
    }

    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements

    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($null -eq $nodeCmd -or $null -eq $npmCmd) {
        throw "Node.js installation completed but node/npm are not available in the current PowerShell session. Open a new PowerShell window and rerun the installer."
    }

    Write-Success "Node.js detected: $(node --version)"
    Write-Success "npm detected: $(npm --version)"
}

function Install-Codex {
    Write-Step "1/4 Installing @openai/codex..."
    Ensure-NodeAndNpm
    npm install -g @openai/codex
    Write-Success "Codex CLI installed"
}

function Write-Config {
    Write-Step "2/4 Writing Codex config..."
    New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
    Backup-File $ConfigFile

    $ConfigContent = @"
model_provider = "codesome"
model = "$Model"
review_model = "$ReviewModel"
model_reasoning_effort = "$ReasoningEffort"
preferred_auth_method = "apikey"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.codesome]
name = "codesome"
base_url = "$BaseUrl"
wire_api = "responses"
env_key = "CODESOME_API_KEY"
"@

    Set-Content -Path $ConfigFile -Value $ConfigContent -Encoding UTF8
    Write-Success "Config written to $ConfigFile"
}

function Persist-ApiKey {
    Write-Step "3/4 Persisting API key to user environment..."
    [Environment]::SetEnvironmentVariable("CODESOME_API_KEY", $Token, "User")
    $env:CODESOME_API_KEY = $Token
    Write-Success "CODESOME_API_KEY saved to your user environment"
}

function Verify-Install {
    Write-Step "4/4 Verifying installation..."
    $codexCmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($null -eq $codexCmd) {
        Write-WarningLine "codex is not on PATH in the current PowerShell session."
        Write-Info "Open a new PowerShell window, then run: codex --version"
        return
    }

    codex --version | Out-Null
    Write-Success "codex --version succeeded"
}

function Show-Summary {
    Write-Host ""
    Write-Host "Codesome Codex Setup Complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Config: $ConfigFile"
    Write-Host "Base:   $BaseUrl"
    Write-Host "Model:  $Model"
    Write-Host "Env:    CODESOME_API_KEY"
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  1. Open a new PowerShell window if codex is not on PATH yet"
    Write-Host "  2. Run: codex"
    Write-Host ""
}

if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "CODEX_TOKEN is required"
}

Install-Codex
Write-Config
Persist-ApiKey
Verify-Install
Show-Summary
