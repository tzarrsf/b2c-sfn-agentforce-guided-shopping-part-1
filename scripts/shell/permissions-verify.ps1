#!/usr/bin/env pwsh

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $ProjectRoot
try
{
    sf apex run --file 'scripts/apex/verify-permission-set-assigned-to-agent.apex'
}
finally
{
    Pop-Location
}