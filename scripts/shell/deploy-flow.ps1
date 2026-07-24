#!/usr/bin/env pwsh

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $ProjectRoot
try
{
    sf project deploy start --source-dir 'force-app/main/default/flows/Route_to_Guided_Shopping_Agent.flow-meta.xml'
}
finally # restore for interactive session
{
    Pop-Location
}