#!/usr/bin/env pwsh
<#
.SYNOPSIS
Orchestrates the setup steps for this Salesforce project.

.DESCRIPTION
Runs all required scripts in sequence.
Stops immediately if any step fails (returns non-zero exit code).
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Step {
    param([Parameter(Mandatory = $true)] [string]$Description,
          [Parameter(Mandatory = $true)] [scriptblock]$Step)
    Write-Host ""
    Write-Host ">>> $Description" -ForegroundColor Cyan
    & $Step
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: '$Description' exited with code $LASTEXITCODE. Aborting." -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "<<< Done: $Description" -ForegroundColor DarkGray
}

#=================== STEPS =========================

Invoke-Step "Process templates in ./force-app" {
    pwsh -File process-templates.ps1 "./force-app" "key-values-table.env"
}

Invoke-Step "Process templates in ./data" {
    pwsh -File process-templates.ps1 "./data" "key-values-table.env"
}

Invoke-Step "5 - Create External Credentials & Named Credentials" {
    pwsh -File scripts/shell/deploy_externalCredentialsFolder.ps1
    pwsh -File scripts/shell/deploy_namedCredentialsFolder.ps1
}

Invoke-Step "6 - Deploy CORS and Trusted URLs" {
    pwsh -File scripts/shell/deploy_corsWhitelistOriginsFolder.ps1
    pwsh -File scripts/shell/deploy_cspTrustedSitesFolder.ps1
}

Invoke-Step "7 - Create and Assign Agent Permission Set" {
    pwsh -File scripts/shell/deploy_permissionSets_B2C_Guided_Shopping_Agent_Permissions.ps1
    pwsh -File scripts/shell/permissions-assign.ps1
    pwsh -File scripts/shell/permissions-verify.ps1
}

Invoke-Step "8 - Add Custom Fields to Messaging Session in Object Manager" {
    pwsh -File scripts/shell/deploy_objectsMessagingSessionFolder.ps1
    pwsh -File scripts/shell/verify-messaging-session-fields.ps1
}


