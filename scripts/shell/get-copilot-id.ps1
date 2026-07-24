#!/usr/bin/env pwsh

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $ProjectRoot
try
{
    sf data query --file 'scripts/soql/get-copilot-id.soql' --json
}
finally # restore for interactive session
{
    Pop-Location
}