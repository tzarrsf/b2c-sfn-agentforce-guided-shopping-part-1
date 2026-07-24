#!/usr/bin/env pwsh

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $ProjectRoot
try
{
    sf project deploy start --source-dir 'force-app/main/default/externalCredentials'
}
finally # restore for interactive session
{
    Pop-Location
}