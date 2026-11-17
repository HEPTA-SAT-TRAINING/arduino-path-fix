# Arduino IDE 2.x: move build cache and Arduino15 data off non-ASCII user paths.
# Windows PowerShell 5.1; standard user; no permanent environment changes.
$ErrorActionPreference = 'Stop'

# Change this one line if C:\ArduinoWork is not writable.
$basePath = 'C:\ArduinoWork'

function Find-Setting {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [string] $Section,
        [string] $Key
    )
    $escapedSection = [regex]::Escape($Section)
    $escapedKey = [regex]::Escape($Key)
    $sections = @()
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match ('^' + $escapedSection + '\s*:')) {
            $sections += $i
        }
    }
    if ($sections.Count -gt 1) {
        throw "Duplicate YAML section: $Section. Edit the file manually."
    }
    if ($sections.Count -eq 0) {
        return [pscustomobject]@{ SectionIndex = -1; KeyIndex = -1; Indent = 2 }
    }
    $start = $sections[0]
    if ($Lines[$start] -notmatch ('^' + $escapedSection + ':\s*(?:#.*)?$')) {
        throw "Unsupported YAML format for '$Section'. Edit the file manually."
    }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
        # A top-level YAML key ends the preceding section.
        if ($Lines[$i] -match '^[A-Za-z_][A-Za-z0-9_-]*\s*:') {
            $end = $i
            break
        }
    }
    $indent = 2
    for ($i = $start + 1; $i -lt $end; $i++) {
        if ($Lines[$i] -match '^( +)[A-Za-z_][A-Za-z0-9_-]*\s*:') {
            $indent = $Matches[1].Length
            break
        }
    }
    $keyIndices = @()
    for ($i = $start + 1; $i -lt $end; $i++) {
        if ($Lines[$i] -match ('^ {' + $indent + '}' + $escapedKey + '\s*:')) {
            $keyIndices += $i
        }
    }
    if ($keyIndices.Count -gt 1) {
        throw "Duplicate YAML setting: $Section.$Key. Edit the file manually."
    }
    $keyIndex = -1
    if ($keyIndices.Count -eq 1) { $keyIndex = $keyIndices[0] }
    return [pscustomobject]@{
        SectionIndex = $start
        KeyIndex = $keyIndex
        Indent = $indent
    }
}

function Set-Setting {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [string] $Section,
        [string] $Key,
        [string] $Value
    )
    $found = Find-Setting -Lines $Lines -Section $Section -Key $Key
    $newLine = (' ' * $found.Indent) + "${Key}: $Value"
    if ($found.SectionIndex -lt 0) {
        $Lines.Add("${Section}:")
        $Lines.Add($newLine)
    } elseif ($found.KeyIndex -ge 0) {
        $Lines[$found.KeyIndex] = $newLine
    } else {
        $Lines.Insert($found.SectionIndex + 1, $newLine)
    }
}

function Get-SettingValue {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [string] $Section,
        [string] $Key
    )
    $found = Find-Setting -Lines $Lines -Section $Section -Key $Key
    if ($found.KeyIndex -lt 0) { return $null }
    $line = $Lines[$found.KeyIndex]
    $value = ($line -replace ('^\s*' + [regex]::Escape($Key) + '\s*:\s*'), '').Trim()
    # Only plain or quoted scalar paths are supported here.
    if ($value -match '^"([^"]*)"\s*(?:#.*)?$') { return $Matches[1] }
    if ($value -match "^'([^']*)'\s*(?:#.*)?$") { return $Matches[1] }
    if ($value -match '^([^#]*?)(?:\s+#.*)?$') { return $Matches[1].Trim() }
    throw "Unsupported YAML value for $Section.$Key."
}

try {
    Write-Host 'Arduino IDE path migration (Windows)' -ForegroundColor Cyan
    Write-Host 'Close ALL Arduino IDE windows before proceeding.'
    $processes = @(Get-Process -Name 'Arduino IDE', 'arduino-cli' -ErrorAction SilentlyContinue)
    if ($processes.Count -gt 0) {
        throw 'Arduino IDE or arduino-cli is still running. Close it in Task Manager and run this script again.'
    }

    $yamlPath = Join-Path (Join-Path $env:USERPROFILE '.arduinoIDE') 'arduino-cli.yaml'
    $oldData = Join-Path $env:LOCALAPPDATA 'Arduino15'
    $newData = Join-Path $basePath 'data'
    $newCache = Join-Path $basePath 'cache'

    if ($basePath -match '[^\x20-\x7E]' -or $basePath -match '[#'']') {
        throw 'The destination path must contain only ASCII characters and no # or apostrophes.'
    }
    if (-not [System.IO.Path]::IsPathRooted($basePath)) {
        throw 'The destination path must be absolute.'
    }

    if (-not (Test-Path -LiteralPath $env:LOCALAPPDATA -PathType Container)) {
        throw 'LOCALAPPDATA could not be found.'
    }
    if (-not (Test-Path -LiteralPath $basePath -PathType Container)) {
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    }
    foreach ($path in @($newData, $newCache)) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    $testFile = Join-Path $newData ('.write-test-' + [guid]::NewGuid().ToString('N'))
    [System.IO.File]::WriteAllText($testFile, 'ok')
    Remove-Item -LiteralPath $testFile -Force

    $lines = New-Object 'System.Collections.Generic.List[string]'
    if (Test-Path -LiteralPath $yamlPath -PathType Leaf) {
        $raw = [System.IO.File]::ReadAllText($yamlPath, [System.Text.Encoding]::UTF8)
        foreach ($line in ($raw -split '\r?\n')) { $lines.Add($line) }
        while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
            $lines.RemoveAt($lines.Count - 1)
        }
    }

    $configuredData = Get-SettingValue -Lines $lines -Section 'directories' -Key 'data'
    if ($configuredData) {
        $configuredData = [Environment]::ExpandEnvironmentVariables($configuredData)
        $configuredData = [System.IO.Path]::GetFullPath($configuredData).TrimEnd('\')
    }
    $oldFull = [System.IO.Path]::GetFullPath($oldData).TrimEnd('\')
    $newFull = [System.IO.Path]::GetFullPath($newData).TrimEnd('\')
    $alreadyMigrated = $configuredData -and $configuredData.Equals($newFull, [StringComparison]::OrdinalIgnoreCase)
    if ($configuredData -and -not $alreadyMigrated -and
        -not $configuredData.Equals($oldFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "directories.data already points to a custom folder: $configuredData. No changes made."
    }

    if (-not $alreadyMigrated) {
        if (-not (Test-Path -LiteralPath $oldData -PathType Container)) {
            throw "Source Arduino15 folder was not found: $oldData. No YAML changes made."
        }
        Write-Host "Copying Arduino15 to: $newData"
        & robocopy.exe $oldData $newData /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NP /NFL /NDL /NJH /NJS
        if ($LASTEXITCODE -ge 8) {
            throw "File copy failed (robocopy exit code $LASTEXITCODE). No YAML changes made."
        }
    } else {
        Write-Host 'directories.data already points to the target. Skipping the copy.'
    }

    Set-Setting -Lines $lines -Section 'build_cache' -Key 'path' -Value $newCache
    Set-Setting -Lines $lines -Section 'directories' -Key 'data' -Value $newData

    $yamlDir = Split-Path -Parent $yamlPath
    if (-not (Test-Path -LiteralPath $yamlDir -PathType Container)) {
        New-Item -Path $yamlDir -ItemType Directory -Force | Out-Null
    }
    $newText = ($lines -join "`r`n") + "`r`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $tempYaml = Join-Path $yamlDir ('.arduino-cli.' + [guid]::NewGuid().ToString('N') + '.tmp')
    [System.IO.File]::WriteAllText($tempYaml, $newText, $utf8NoBom)

    if (Test-Path -LiteralPath $yamlPath -PathType Leaf) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $backupPath = "$yamlPath.backup-$stamp"
        Copy-Item -LiteralPath $yamlPath -Destination $backupPath -ErrorAction Stop
        [System.IO.File]::Replace($tempYaml, $yamlPath, $null)
        Write-Host "YAML backup: $backupPath"
    } else {
        [System.IO.File]::Move($tempYaml, $yamlPath)
    }

    Write-Host ''
    Write-Host 'SUCCESS: Arduino paths updated.' -ForegroundColor Green
    Write-Host "  build_cache.path = $newCache"
    Write-Host "  directories.data = $newData"
    Write-Host 'Original Arduino15 files were NOT deleted.'
    Write-Host 'Start Arduino IDE and compile Blink to verify.'
    exit 0
} catch {
    Write-Host ''
    Write-Host 'ERROR: Migration was not completed.' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'The original Arduino15 folder was not deleted.'
    exit 1
}
