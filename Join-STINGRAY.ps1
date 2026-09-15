# Copyright 2026 STINGRAY contributors
# SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [ValidateSet('Both','Source','Portable')][string]$Package = 'Both',
    [string]$PartsDirectory,
    [string]$OutputDirectory,
    [switch]$VerifyOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-SHA256([string]$Path) {
    $hasher = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try {
        return [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','').ToLowerInvariant()
    } finally { $stream.Dispose(); $hasher.Dispose() }
}
function Assert-PlainPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Choose a regular folder rather than a linked folder: $current"
            }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
try {
    # $PSScriptRoot can be empty in param defaults on some Windows PowerShell hosts; resolve it here.
    if ([string]::IsNullOrWhiteSpace($PartsDirectory)) {
        $scriptDir = $PSScriptRoot
        if ([string]::IsNullOrWhiteSpace($scriptDir) -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
        if ([string]::IsNullOrWhiteSpace($scriptDir)) { $scriptDir = (Get-Location).ProviderPath }
        $PartsDirectory = $scriptDir
    }
    $PartsDirectory = (Resolve-Path -LiteralPath $PartsDirectory).ProviderPath
    $manifest = Get-Content -LiteralPath (Join-Path $PartsDirectory 'STINGRAY-parts.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.format -ne 'stingray-parts-1' -or $manifest.partLimitBytes -ne 24000000) { throw 'Unsupported parts manifest.' }
    $selected = @($manifest.archives | Where-Object { $Package -eq 'Both' -or $_.package -eq $Package })
    if ($selected.Count -ne $(if ($Package -eq 'Both') { 2 } else { 1 })) { throw 'The manifest does not contain the requested packages.' }
    $seen = @{}
    foreach ($archive in $selected) {
        $expectedFile = if ($archive.package -eq 'Source') { 'STINGRAY-v20-Source-Compiler.zip' } elseif ($archive.package -eq 'Portable') { 'STINGRAY-v20-Portable.zip' } else { throw 'Unknown package in manifest.' }
        if ($archive.file -cne $expectedFile -or $seen.ContainsKey($archive.file)) { throw 'Invalid or duplicate archive name.' }
        $seen[$archive.file] = $true
        if ($archive.sha256 -notmatch '^[a-f0-9]{64}$' -or $archive.bytes -le 0) { throw 'Invalid archive checksum or size.' }
        $parts = @($archive.parts)
        if ($parts.Count -ne [math]::Ceiling($archive.bytes / 24000000.0)) { throw 'Incorrect part count.' }
        [long]$total = 0
        for ($index = 0; $index -lt $parts.Count; $index++) {
            $part = $parts[$index]
            $expected = '{0}.part{1:d3}' -f $archive.file, ($index + 1)
            $expectedBytes = [math]::Min(24000000, $archive.bytes - $total)
            if ($part.file -cne $expected -or $part.bytes -ne $expectedBytes -or $part.sha256 -notmatch '^[a-f0-9]{64}$') { throw "Invalid part entry: $expected" }
            $partPath = Join-Path $PartsDirectory $part.file
            if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) { throw "Missing part: $($part.file). Download it into the same folder and try again." }
            if ((Get-Item -LiteralPath $partPath).Length -ne $part.bytes -or (Get-SHA256 $partPath) -ne $part.sha256) { throw "Damaged or incomplete part: $($part.file). Download that part again." }
            $total += $part.bytes
            Write-Host "Verified $($part.file)"
        }
        if ($total -ne $archive.bytes) { throw 'Part sizes do not match the archive.' }
    }
    if ($VerifyOnly) { Write-Host 'All requested parts passed verification.'; exit 0 }
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PartsDirectory 'assembled' }
    $OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
    Assert-PlainPath $OutputDirectory
    $null = New-Item -ItemType Directory -Path $OutputDirectory -Force
    foreach ($archive in $selected) {
        $destination = Join-Path $OutputDirectory $archive.file
        Assert-PlainPath $destination
        if (Test-Path -LiteralPath $destination) {
            if ((Test-Path -LiteralPath $destination -PathType Leaf) -and (Get-SHA256 $destination) -eq $archive.sha256) { Write-Host "Already assembled and verified: $destination"; continue }
            throw "A different file already exists at $destination. Choose another output folder; it has not been overwritten."
        }
        $temporary = Join-Path $OutputDirectory ('.stingray-' + [guid]::NewGuid().ToString('N') + '.partial')
        try {
            $output = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                foreach ($part in $archive.parts) {
                    $inputStream = [IO.File]::OpenRead((Join-Path $PartsDirectory $part.file))
                    try { $inputStream.CopyTo($output, 1048576) } finally { $inputStream.Dispose() }
                }
                $output.Flush()
            } finally { $output.Dispose() }
            if ((Get-Item -LiteralPath $temporary).Length -ne $archive.bytes -or (Get-SHA256 $temporary) -ne $archive.sha256) { throw "The assembled archive failed verification: $($archive.file)" }
            [IO.File]::Move($temporary, $destination)
            Write-Host "Ready: $destination"
        } finally {
            if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
        }
    }
    Write-Host 'Right-click each completed ZIP and choose Extract All. Read INSTRUCTIONS.txt before opening STINGRAY.'
    exit 0
} catch {
    Write-Host ('Unable to assemble STINGRAY: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
