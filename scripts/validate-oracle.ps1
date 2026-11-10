<#
.SYNOPSIS
    Validates the SOC 2 testbed answer key (oracle/expected-findings.yml),
    secrets registry, anchors, files, and safeguards against unregistered credentials.

.DESCRIPTION
    Enforces the answer key schema v1, ensures all referenced files and text anchors
    exist in the working tree, confirms all committed secrets are registered, and guards
    against accidental live secret patterns. Exits with 0 on success, 1 on failure.

.PARAMETER RepoRoot
    Optional root directory of the repository. Defaults to the parent directory of this script.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
} else {
    $RepoRoot = Resolve-Path $RepoRoot
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Running SOC 2 Testbed Oracle Validator" -ForegroundColor Cyan
Write-Host " Repo Root: $RepoRoot" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error([string]$msg) {
    Write-Host "[ERROR] $msg" -ForegroundColor Red
    $errors.Add($msg)
}

function Add-Warning([string]$msg) {
    Write-Host "[WARN]  $msg" -ForegroundColor Yellow
    $warnings.Add($msg)
}

function Add-Success([string]$msg) {
    Write-Host "[OK]    $msg" -ForegroundColor Green
}

# -------------------------------------------------------------
# 1. Pure-PowerShell YAML Parser for Oracle Schema v1
# -------------------------------------------------------------
function Parse-SimpleYaml {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }

    $lines = Get-Content -Path $Path
    $result = [ordered]@{}
    $currentSection = $null
    $currentItem = $null

    foreach ($rawLine in $lines) {
        $line = $rawLine -replace '\s+#.*$', ''
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        # Top-level scalar: key: value
        if ($line -match '^([a-zA-Z0-9_-]+):\s*(.*)$' -and -not ($line -match '^\s+')) {
            $key = $matches[1]
            $val = $matches[2].Trim()

            if ($val -eq '[]') {
                $result[$key] = [System.Collections.Generic.List[object]]::new()
                $currentSection = $null
                $currentItem = $null
            } elseif ($val -eq '') {
                $currentSection = $key
                $result[$key] = [System.Collections.Generic.List[object]]::new()
                $currentItem = $null
            } else {
                $result[$key] = $val.Trim('"').Trim("'")
                $currentSection = $null
                $currentItem = $null
            }
            continue
        }

        # Sub-key of map: e.g. secrets: \n  registry: path
        if ($line -match '^\s{2}([a-zA-Z0-9_-]+):\s*(.*)$' -and -not ($line -match '^\s{2}-\s+')) {
            $subKey = $matches[1]
            $subVal = $matches[2].Trim().Trim('"').Trim("'")
            if ($currentSection) {
                if (-not ($result[$currentSection] -is [System.Collections.IDictionary])) {
                    $result[$currentSection] = [ordered]@{}
                }
                $result[$currentSection][$subKey] = $subVal
            }
            continue
        }

        # List item start: e.g.   - id: TB-001
        if ($line -match '^\s{2}-\s+([a-zA-Z0-9_-]+):\s*(.*)$') {
            $k = $matches[1]
            $v = $matches[2].Trim().Trim('"').Trim("'")
            $currentItem = [ordered]@{$k = $v}
            if (-not ($result[$currentSection] -is [System.Collections.Generic.List[object]])) {
                $result[$currentSection] = [System.Collections.Generic.List[object]]::new()
            }
            $result[$currentSection].Add($currentItem) | Out-Null
            continue
        }

        # List item property: e.g.     checkId: SEC-001
        if ($line -match '^\s{4}([a-zA-Z0-9_-]+):\s*(.*)$') {
            $k = $matches[1]
            $rawV = $matches[2].Trim()
            if ($rawV -match '^\[(.*)\]$') {
                $items = $matches[1].Split(',') | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne '' }
                $v = @($items)
            } elseif ($rawV -match '^\{(.*)\}$') {
                $map = [ordered]@{}
                $matches[1].Split(',') | ForEach-Object {
                    if ($_ -match '([a-zA-Z0-9_-]+)\s*:\s*([^,]+)') {
                        $map[$matches[1].Trim()] = $matches[2].Trim().Trim('"').Trim("'")
                    }
                }
                $v = $map
            } else {
                $v = $rawV.Trim('"').Trim("'")
            }
            if ($currentItem) {
                $currentItem[$k] = $v
            }
            continue
        }
    }

    return ,$result
}

# -------------------------------------------------------------
# 2. Validate expected-findings.yml presence and schema
# -------------------------------------------------------------
$oraclePath = Join-Path $RepoRoot "oracle\expected-findings.yml"
if (-not (Test-Path $oraclePath)) {
    Add-Error "Missing oracle file at oracle/expected-findings.yml"
} else {
    Add-Success "Found oracle file at oracle/expected-findings.yml"
}

if ($errors.Count -gt 0) {
    Write-Host "`nValidation FAILED with $($errors.Count) errors." -ForegroundColor Red
    exit 1
}

try {
    $oracle = Parse-SimpleYaml -Path $oraclePath
} catch {
    Add-Error "Failed to parse oracle YAML: $_"
    exit 1
}

# Check root fields
$requiredRootKeys = @('schemaVersion', 'repoState', 'generated', 'issues', 'negatives', 'canaries', 'secrets')
foreach ($rk in $requiredRootKeys) {
    if (-not $oracle.Contains($rk)) {
        Add-Error "Oracle root missing required property: '$rk'"
    }
}

if ($oracle.schemaVersion -ne 1 -and $oracle.schemaVersion -ne '1') {
    Add-Error "Unsupported schemaVersion '$($oracle.schemaVersion)'; expected 1"
} else {
    Add-Success "Oracle schemaVersion is 1"
}

if ([string]::IsNullOrWhiteSpace($oracle.repoState)) {
    Add-Error "Oracle repoState is empty"
} else {
    Add-Success "Oracle repoState: '$($oracle.repoState)'"
}

# -------------------------------------------------------------
# 3. Validate Issues
# -------------------------------------------------------------
$seenIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$validCategories = @('Code', 'Configuration', 'Process')
$validSeverities = @('critical', 'high', 'medium', 'low', 'info')
$validDetections = @('required', 'best-effort', 'environment-dependent')

    $issues = $oracle.issues; if (-not $issues) { $issues = @() }
Write-Host "`n--- Validating Issues (Count: $($issues.Count)) ---" -ForegroundColor Cyan

# State-aware assertions on issues count
if ($oracle.repoState -eq 'stage0-bootstrap') {
    if ($issues.Count -eq 0) {
        Add-Success "Issues list is empty (valid for Stage 0 bootstrap)"
    } else {
        Add-Warning "Stage 0 is expected to have an empty issues list, but found $($issues.Count) issues."
    }
} elseif ($oracle.repoState -like 'stage*-wip*') {
    Add-Success "Issues count is $($issues.Count) (in-progress stage $($oracle.repoState))"
} else {
    if ($issues.Count -eq 0) {
        Add-Error "repoState is '$($oracle.repoState)' but issues list is empty. Seeded issues are required for non-bootstrap stages."
    }
}

foreach ($issue in $issues) {
    $id = $issue['id']
    if ([string]::IsNullOrWhiteSpace($id)) {
        Add-Error "Found issue without an 'id'"
        continue
    }

    if (-not $seenIds.Add($id)) {
        Add-Error "Duplicate issue ID detected: '$id'"
    }

    # Required fields
    $reqIssueFields = @('checkId', 'title', 'category', 'expectedSeverity', 'file', 'anchor', 'defaultTsc', 'detection', 'expectedSources', 'remediation', 'verified')
    foreach ($f in $reqIssueFields) {
        if (-not $issue.Contains($f) -or [string]::IsNullOrWhiteSpace($issue[$f])) {
            Add-Error "Issue '$id' missing or empty required field '$f'"
        }
    }

    # Enums
    if ($validCategories -notcontains $issue['category']) {
        Add-Error "Issue '$id' has invalid category '$($issue['category'])'. Expected: $($validCategories -join ', ')"
    }
    if ($validSeverities -notcontains $issue['expectedSeverity']) {
        Add-Error "Issue '$id' has invalid expectedSeverity '$($issue['expectedSeverity'])'. Expected: $($validSeverities -join ', ')"
    }
    if ($validDetections -notcontains $issue['detection']) {
        Add-Error "Issue '$id' has invalid detection '$($issue['detection'])'. Expected: $($validDetections -join ', ')"
    }

    # Anchor checks: never a line number
    $anchor = $issue['anchor']
    if ($anchor -match '^(#?L)?\d+$' -or $anchor -match '^line\s*\d+$') {
        Add-Error "Issue '$id' anchor '$anchor' appears to be a line number. Line numbers are strictly forbidden as anchors."
    }

    # File and anchor verification
    $relFile = $issue['file']
    $fullFile = Join-Path $RepoRoot $relFile
    if (-not (Test-Path $fullFile)) {
        Add-Error "Issue '$id' references non-existent file: '$relFile'"
    } else {
        $fileContent = Get-Content -Path $fullFile -Raw
        if (-not $fileContent.Contains($anchor)) {
            Add-Error "Issue '$id' anchor text '$anchor' not found in file '$relFile'"
        } else {
            Add-Success "Issue '$id' file '$relFile' anchor verified"
        }
    }
}

# -------------------------------------------------------------
# 4. Validate Negatives and Traps
# -------------------------------------------------------------
    $negatives = $oracle.negatives; if (-not $negatives) { $negatives = @() }
Write-Host "`n--- Validating Negatives (Count: $($negatives.Count)) ---" -ForegroundColor Cyan

if ($oracle.repoState -eq 'stage0-bootstrap' -and $negatives.Count -eq 0) {
    Add-Success "Negatives list is empty (valid for Stage 0 bootstrap)"
}

foreach ($neg in $negatives) {
    $id = $neg['id']
    if ([string]::IsNullOrWhiteSpace($id)) {
        Add-Error "Found negative fixture without an 'id'"
        continue
    }

    if (-not $seenIds.Add($id)) {
        Add-Error "Duplicate ID across issues/negatives detected: '$id'"
    }

    $reqNegFields = @('file', 'anchor', 'mustNotFlag', 'why')
    foreach ($f in $reqNegFields) {
        if (-not $neg.Contains($f) -or $null -eq $neg[$f]) {
            Add-Error "Negative '$id' missing required field '$f'"
        }
    }

    $anchor = $neg['anchor']
    if ($anchor -match '^(#?L)?\d+$' -or $anchor -match '^line\s*\d+$') {
        Add-Error "Negative '$id' anchor '$anchor' appears to be a line number."
    }

    $relFile = $neg['file']
    $fullFile = Join-Path $RepoRoot $relFile
    if (-not (Test-Path $fullFile)) {
        Add-Error "Negative '$id' references non-existent file: '$relFile'"
    } else {
        $fileContent = Get-Content -Path $fullFile -Raw
        if (-not $fileContent.Contains($anchor)) {
            Add-Error "Negative '$id' anchor text '$anchor' not found in file '$relFile'"
        } else {
            Add-Success "Negative '$id' file '$relFile' anchor verified"
        }
    }
}

# -------------------------------------------------------------
# 5. Validate Canaries
# -------------------------------------------------------------
    $canaries = $oracle.canaries; if (-not $canaries) { $canaries = @() }
Write-Host "`n--- Validating Canaries (Count: $($canaries.Count)) ---" -ForegroundColor Cyan

if ($oracle.repoState -eq 'stage0-bootstrap' -and $canaries.Count -eq 0) {
    Add-Success "Canaries list is empty (valid for Stage 0 bootstrap)"
}

foreach ($canary in $canaries) {
    $id = $canary['id']
    if ([string]::IsNullOrWhiteSpace($id)) {
        Add-Error "Found canary without an 'id'"
        continue
    }

    if (-not $seenIds.Add($id)) {
        Add-Error "Duplicate ID across issues/canaries detected: '$id'"
    }

    $reqCanaryFields = @('project', 'marker', 'meaning')
    foreach ($f in $reqCanaryFields) {
        if (-not $canary.Contains($f) -or [string]::IsNullOrWhiteSpace($canary[$f])) {
            Add-Error "Canary '$id' missing or empty required field '$f'"
        }
    }

    $relProj = $canary['project']
    $fullProj = Join-Path $RepoRoot $relProj
    if (-not (Test-Path $fullProj)) {
        Add-Error "Canary '$id' references non-existent project: '$relProj'"
    } else {
        Add-Success "Canary '$id' project '$relProj' verified"
    }
}

# -------------------------------------------------------------
# 6. Validate Secrets Registry and Template
# -------------------------------------------------------------
Write-Host "`n--- Validating Secrets Registry ---" -ForegroundColor Cyan
$registryRelPath = if ($oracle.secrets -and $oracle.secrets['registry']) { $oracle.secrets['registry'] } else { $null }

if (-not $registryRelPath) {
    Add-Error "Oracle secrets.registry is not specified"
} else {
    $registryFullPath = Join-Path $RepoRoot $registryRelPath
    if (Test-Path $registryFullPath) {
        Add-Success "Secrets registry file exists at '$registryRelPath'"
        try {
            $regContent = Get-Content -Path $registryFullPath -Raw | ConvertFrom-Json
            if (-not $regContent.secrets) {
                Add-Error "Secrets registry missing 'secrets' array"
            } else {
                foreach ($sec in $regContent.secrets) {
                    if ($sec.scope -eq 'committed-generic') {
                        $sFile = Join-Path $RepoRoot $sec.file
                        if (-not (Test-Path $sFile)) {
                            Add-Error "Registered secret '$($sec.id)' file '$($sec.file)' not found"
                        } else {
                            $sc = Get-Content -Path $sFile -Raw
                            if (-not $sc.Contains($sec.anchor)) {
                                Add-Error "Registered secret '$($sec.id)' anchor not found in '$($sec.file)'"
                            }
                        }
                    }
                }
            }
        } catch {
            Add-Error "Secrets registry at '$registryRelPath' is invalid JSON: $_"
        }
    } else {
        Add-Success "Secrets registry not yet created on disk (acceptable for Stage 0 before secret seeding)"
    }
}

# Validate secrets-registry.template.json if present
$templatePath = Join-Path $RepoRoot "oracle\secrets-registry.template.json"
if (Test-Path $templatePath) {
    try {
        $tmpl = Get-Content -Path $templatePath -Raw | ConvertFrom-Json
        if (-not $tmpl.secrets) {
            Add-Error "Template at oracle/secrets-registry.template.json missing 'secrets' array"
        } else {
            Add-Success "Secrets registry template exists and has valid JSON structure"
        }
    } catch {
        Add-Error "Failed to parse oracle/secrets-registry.template.json: $_"
    }
}

# -------------------------------------------------------------
# 7. Accidental Live Credential Scan Guard
# -------------------------------------------------------------
Write-Host "`n--- Scanning for Unregistered / Accidental Live Credentials ---" -ForegroundColor Cyan

$excludedDirs = @('.git', 'artifacts', 'fixtures-generated', '.vs', 'bin', 'obj', 'node_modules')
$excludedFiles = @('validate-oracle.ps1', 'secrets-registry.json', 'secrets-registry.schema.md', 'secrets-registry.template.json', 'plan.md', 'README.md')

$patterns = @(
    @{ Name = "AWS Access Key"; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = "GitHub Personal Access Token"; Pattern = 'ghp_[0-9a-zA-Z]{36}' },
    @{ Name = "GitHub OAuth Access Token"; Pattern = 'gho_[0-9a-zA-Z]{36}' },
    @{ Name = "Slack Token"; Pattern = 'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*' },
    @{ Name = "Private Key Header"; Pattern = '-----BEGIN (RSA|EC|OPENSSH|DSA|PRIVATE) KEY-----' }
)

$allFiles = Get-ChildItem -Path $RepoRoot -Recurse -File | Where-Object {
    $file = $_
    $rel = $file.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
    $parts = $rel.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    $isExcludedDir = $false
    foreach ($p in $parts) {
        if ($excludedDirs -contains $p) { $isExcludedDir = $true; break }
    }
    if ($isExcludedDir) { return $false }
    if ($excludedFiles -contains $file.Name) { return $false }
    return $true
}

$liveSecretHits = 0
foreach ($f in $allFiles) {
    $text = Get-Content -Path $f.FullName -Raw
    foreach ($p in $patterns) {
        if ($text -match $p.Pattern) {
            Add-Error "Potential unregistered live credential pattern ($($p.Name)) detected in: $($f.FullName.Substring($RepoRoot.Length).TrimStart('\', '/'))"
            $liveSecretHits++
        }
    }
}

if ($liveSecretHits -eq 0) {
    Add-Success "No unregistered credential patterns detected in committed files"
}

# -------------------------------------------------------------
# Summary and Exit
# -------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Oracle Validation Summary" -ForegroundColor Cyan
Write-Host " Errors:   $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Red" })
Write-Host " Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($errors.Count -gt 0) {
    Write-Host "`nValidation FAILED." -ForegroundColor Red
    exit 1
}

Write-Host "`nValidation PASSED." -ForegroundColor Green
exit 0





