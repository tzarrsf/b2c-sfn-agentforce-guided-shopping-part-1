#!/usr/bin/env pwsh

<#
.DESCRIPTION
The script replaces placeholders in the {KEY} format with the values defined in the templates.txt file.
Placeholders are replaced both in the contents of all files and in their filenames.
When renaming files, the filename is sanitized to comply with Salesforce requirements:
  The portion of the filename before the first dot is treated as the API name and may contain
  only alphanumeric characters and underscores. It must not contain consecutive underscores or
  start or end with an underscore.

Usage:
  ./process-templates.ps1 <path-to-folder> [key-values-file]

.EXAMPLEs
./process-templates.ps1 "./force-app"
./process-templates.ps1 "./force-app" "key-values-table.env"

path-to-folder  is the path to the root folder containing the templates.
                The script will process all files in this folder and its subfolders.

key-values-file is a text file containing KEY=value pairs, one per line.
            Lines starting with '#' are treated as comments and ignored.
            multiline values are not supported. Values MUST NOT be enclosed in quotes.
            Spaces around the value are trimmed.
            If key-values-file is not provided, the script will look for a file named "key-values-table.env"
            in the same folder as the current script.

It runs 2 stages:
1) File content stage: Replaces {KEY} placeholders in the content of all files (including subfolders).
2) Filename stage: Replaces {KEY} placeholders in file names and applies sanitization.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the folder containing template files")]
    [string]$RootFolderPath,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Path to the KEY=value file (optional, defaults to key-values-table.env next to this script)")]
    [string]$ValuesFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:ErrorCount = 0

function Write-Pass
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host $Message -ForegroundColor Green
}

function Write-Fail
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $script:ErrorCount++
    Write-Host $Message -ForegroundColor Red
}

function Convert-ToFilenameTokenValue
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $lower = $Value.ToLowerInvariant()
    return [regex]::Replace($lower, '[^a-z0-9]+', '_')
}

function Sanitize-OutputFilename
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Filename
    )

    $dotIndex = $Filename.IndexOf(".")
    if ($dotIndex -ge 0)
    {
        $namePart = $Filename.Substring(0, $dotIndex)
        $suffix = $Filename.Substring($dotIndex)
    }
    else
    {
        $namePart = $Filename
        $suffix = ""
    }

    $namePart = [regex]::Replace($namePart, '_{2,}', '_').Trim("_")
    return $namePart + $suffix
}

function Replace-TemplateTokens
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputText,

        [Parameter(Mandatory = $true)]
        [hashtable]$TokenMap,

        [Parameter(Mandatory = $true)]
        [ref]$ReplacementCount
    )

    $result = $InputText
    $total = 0

    foreach ($entry in $TokenMap.GetEnumerator())
    {
        $key = [string]$entry.Key
        $value = [string]$entry.Value
        $pattern = '\{' + [regex]::Escape($key) + '\}'
        $matchCount = [regex]::Matches($result, $pattern).Count

        if ($matchCount -gt 0)
        {
            $total += $matchCount
            $replacementValue = $value
            $result = [regex]::Replace(
                    $result,
                    $pattern,
                    {
                        param($match)
                        return $replacementValue
                    }
            )
        }
    }

    $ReplacementCount.Value = $total
    return $result
}

if (-not (Test-Path -LiteralPath $RootFolderPath -PathType Container))
{
    throw "Templates folder not found: $RootFolderPath"
}

if ([string]::IsNullOrEmpty($ValuesFile)) {
    $ValuesFile = Join-Path -Path $PSScriptRoot -ChildPath "key-values-table.env"
    Write-Host "INFO: ValuesFile not provided, using default: $ValuesFile"
}

if (-not (Test-Path -LiteralPath $ValuesFile -PathType Leaf))
{
    throw "Values file not found: $ValuesFile"
}

# Read KEY=value map
$tokenMap = @{ }
foreach ($line in Get-Content -LiteralPath $ValuesFile)
{
    $trimmedLineStart = $line.TrimStart()
    if ( $trimmedLineStart.StartsWith("#"))
    {
        continue
    }

    $idx = $line.IndexOf("=")
    if ($idx -lt 0)
    {
        continue
    }

    $key = $line.Substring(0, $idx).Trim()
    if ( [string]::IsNullOrEmpty($key))
    {
        continue
    }

    # Everything after first '=' is value, with trimmed spaces
    $value = $line.Substring($idx + 1).Trim()
    $tokenMap[$key] = $value
}

Write-Host "Stage 1: Replace placeholders in file content"
# Pass 1: replace placeholders in file content
$files = Get-ChildItem -LiteralPath $RootFolderPath -Recurse -File
$totalReplacementCount = 0
foreach ($file in $files)
{
    Write-Host "Processing file: $( $file.FullName )"  -ForegroundColor Gray
    try
    {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $replacementCount = 0
        $newContent = Replace-TemplateTokens -InputText $content -TokenMap $tokenMap -ReplacementCount ([ref]$replacementCount)

        if ($newContent -ne $content)
        {
            Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding utf8 -NoNewline
            Write-Pass "PASS: $replacementCount templates replaced"
        }

        $totalReplacementCount += $replacementCount
    }
    catch
    {
        Write-Fail "FAIL: $( $_.Exception.Message )"
    }
}

Write-Host "Stage 2: Rename files by placeholders in filename"

# Pass 2: rename files by placeholders in filename
$filenameTokenMap = @{ }
foreach ($entry in $tokenMap.GetEnumerator())
{
    $filenameTokenMap[[string]$entry.Key] = Convert-ToFilenameTokenValue -Value ([string]$entry.Value)
}

$filesForRename = Get-ChildItem -LiteralPath $RootFolderPath -Recurse -File
$renamedFilesCount = 0
foreach ($file in $filesForRename)
{
    $filename = $file.Name

    if (($filename -notlike "*{*") -and ($filename -notlike "*}*"))
    {
        continue
    }

    Write-Host "Processing file: $( $file.FullName )"  -ForegroundColor Gray

    $dummyCount = 0
    $newFilename = Replace-TemplateTokens -InputText $filename -TokenMap $filenameTokenMap -ReplacementCount ([ref]$dummyCount)

    if (($newFilename -like "*{*") -or ($newFilename -like "*}*"))
    {
        Write-Fail "FAIL: filename contains unknown template: $newFilename"
        continue
    }

    $newFilename = Sanitize-OutputFilename -Filename $newFilename

    if ($newFilename.StartsWith(".")) {
        Write-Fail "FAIL: Salesforce API name (part before the first dot) cannot be empty in: $newFilename"
        continue
    }

    if ($newFilename -eq $filename)
    {
        Write-Pass "PASS: renamed to $newFilename"
        continue
    }

    $targetPath = Join-Path -Path $file.DirectoryName -ChildPath $newFilename
    if ((Test-Path -LiteralPath $targetPath) -and ($targetPath -ne $file.FullName))
    {
        Write-Fail "FAIL: target file already exists: $targetPath"
        continue
    }

    try
    {
        Rename-Item -LiteralPath $file.FullName -NewName $newFilename -ErrorAction Stop
        $renamedFilesCount++
        Write-Pass "PASS: renamed to $newFilename"
    }
    catch
    {
        Write-Fail "FAIL: $( $_.Exception.Message )"
    }
}

Write-Host "DONE: $totalReplacementCount templates replaced in content; $renamedFilesCount files renamed"

if ($script:ErrorCount -gt 0)
{
    Write-Fail "$script:ErrorCount errors found"
    exit 1
}

exit 0