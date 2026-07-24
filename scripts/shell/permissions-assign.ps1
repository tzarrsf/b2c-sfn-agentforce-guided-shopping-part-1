#!/usr/bin/env pwsh

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $ProjectRoot
try
{
    sf apex run --file 'scripts/apex/assign-permission-set-to-agent.apex'
}
finally
{
    Pop-Location
}