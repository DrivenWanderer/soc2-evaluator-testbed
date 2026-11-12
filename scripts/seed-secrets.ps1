<#
.SYNOPSIS
    Generates synthetic provider-pattern fake secrets and builds oracle/secrets-registry.json.

.DESCRIPTION
    Per Decision D2, generic fake secrets are safely committed, while provider-pattern
    fake secrets (AWS, GitHub, Slack tokens) are generated at test-time into gitignored
    fixtures to prevent GitHub push-protection blocks. This script creates the dynamic
    fixtures and generates the combined secrets registry at oracle/secrets-registry.json.

.PARAMETER Clean
    If specified, removes generated fixtures and oracle/secrets-registry.json.

.PARAMETER RepoRoot
    Optional repo root directory. Defaults to parent directory of this script.
#>

[CmdletBinding()]
param(
    [switch]$Clean,
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
} else {
    $RepoRoot = Resolve-Path $RepoRoot
}

$registryPath = Join-Path $RepoRoot "oracle\secrets-registry.json"
$fixturesDir = Join-Path $RepoRoot "fixtures-generated\secrets"

if ($Clean) {
    Write-Host "Cleaning generated secrets fixtures and registry..." -ForegroundColor Yellow
    if (Test-Path $registryPath) { Remove-Item $registryPath -Force }
    if (Test-Path $fixturesDir) { Remove-Item $fixturesDir -Recurse -Force }
    Write-Host "Clean completed." -ForegroundColor Green
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Generating Synthetic Secrets & Secrets Registry" -ForegroundColor Cyan
Write-Host " Repo Root: $RepoRoot" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# Ensure fixtures-generated directory exists
if (-not (Test-Path $fixturesDir)) {
    New-Item -ItemType Directory -Path $fixturesDir -Force | Out-Null
}

# 1. Committed Generic Fake Secrets (present in source / config)
$committedSecrets = @(
    [ordered]@{
        id = "SEC-REG-001"
        type = "connection-string-password"
        value = "SyntheticLedgerlySecret2026!"
        file = "src/ModernApi/appsettings.json"
        anchor = "Password="
        scope = "committed-generic"
        description = "Synthetic SQL connection string password in ModernApi appsettings"
    },
    [ordered]@{
        id = "SEC-REG-002"
        type = "jwt-signing-key"
        value = "SyntheticShortSecretKey123!"
        file = "src/ModernApi/Program.cs"
        anchor = "SyntheticShortSecretKey123!"
        scope = "committed-generic"
        description = "Short hardcoded symmetric JWT signing key in ModernApi"
    },
    [ordered]@{
        id = "SEC-REG-003"
        type = "generic-api-key"
        value = "ledgerly_fake_api_key_99887766554433221100"
        file = "src/ModernApi/Services/PaymentGatewayService.cs"
        anchor = "ledgerly_fake_api_key_99887766554433221100"
        scope = "committed-generic"
        description = "Synthetic payment gateway API key constant"
    },
    [ordered]@{
        id = "SEC-REG-004"
        type = "connection-string-password"
        value = "LegacyPortalFakeSqlPassword2026#"
        file = "src/LegacyPortal/web.config"
        anchor = "Password="
        scope = "committed-generic"
        description = "Synthetic connection string password in LegacyPortal web.config"
    }
)

# 2. Dynamic Provider-Pattern Fake Secrets (generated only at test time)
$providerSecretsFile = Join-Path $fixturesDir "provider-secrets.env"
$awsKey = "AKIA" + "IOSFODNN7EXAMPLE"
$ghToken = "ghp_" + "FakeSyntheticGitHubToken0123456789abcd"
$slackToken = "xoxb-" + "0000000000-000000000000-FakeSyntheticSlackToken0001"

$envContent = @"
# DYNAMIC TEST-TIME FIXTURE - SYNTHETIC SECRETS ONLY - NEVER USE IN PRODUCTION
AWS_ACCESS_KEY_ID=$awsKey
GITHUB_TOKEN=$ghToken
SLACK_BOT_TOKEN=$slackToken
"@

Set-Content -Path $providerSecretsFile -Value $envContent -Encoding utf8
Write-Host "[OK] Wrote provider secrets fixture to fixtures-generated/secrets/provider-secrets.env" -ForegroundColor Green

$generatedSecrets = @(
    [ordered]@{
        id = "SEC-REG-101"
        type = "aws-access-key-id"
        value = $awsKey
        file = "fixtures-generated/secrets/provider-secrets.env"
        anchor = "AWS_ACCESS_KEY_ID="
        scope = "generated-provider"
        description = "Generated AWS access key pattern for redaction testing"
    },
    [ordered]@{
        id = "SEC-REG-102"
        type = "github-personal-access-token"
        value = $ghToken
        file = "fixtures-generated/secrets/provider-secrets.env"
        anchor = "GITHUB_TOKEN="
        scope = "generated-provider"
        description = "Generated GitHub token pattern for redaction testing"
    },
    [ordered]@{
        id = "SEC-REG-103"
        type = "slack-bot-token"
        value = $slackToken
        file = "fixtures-generated/secrets/provider-secrets.env"
        anchor = "SLACK_BOT_TOKEN="
        scope = "generated-provider"
        description = "Generated Slack bot token pattern for redaction testing"
    }
)

# 3. Assemble and write oracle/secrets-registry.json
$allSecrets = $committedSecrets + $generatedSecrets
$registry = [ordered]@{
    '$schema' = "https://json-schema.org/draft/2020-12/schema"
    version = 1
    generated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    secrets = $allSecrets
}

$jsonContent = $registry | ConvertTo-Json -Depth 5
Set-Content -Path $registryPath -Value $jsonContent -Encoding utf8

Write-Host "[OK] Generated oracle/secrets-registry.json with $($allSecrets.Count) entries ($($committedSecrets.Count) committed-generic, $($generatedSecrets.Count) generated-provider)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
