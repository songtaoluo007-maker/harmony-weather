[CmdletBinding()]
param(
    [switch]$RestartDaemon
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $projectRoot 'local.properties'

if (-not (Test-Path -LiteralPath $propertiesPath)) {
    throw 'local.properties is missing. Open the project once in DevEco Studio to generate it.'
}

$properties = @{}
Get-Content -LiteralPath $propertiesPath | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        $properties[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$sdkHome = $properties['hwsdk.dir']
$nodeDirectory = $properties['nodejs.dir']
if (-not $sdkHome -or -not (Test-Path -LiteralPath $sdkHome)) {
    throw "Invalid hwsdk.dir in local.properties: $sdkHome"
}
if (-not $nodeDirectory -or -not (Test-Path -LiteralPath $nodeDirectory)) {
    throw "Invalid nodejs.dir in local.properties: $nodeDirectory"
}

$env:DEVECO_SDK_HOME = $sdkHome
$node = Join-Path $nodeDirectory 'node.exe'
$toolsDirectory = Split-Path -Parent $nodeDirectory
$hvigor = Join-Path $toolsDirectory 'hvigor\bin\hvigorw.js'

if ($RestartDaemon) {
    & $node $hvigor --stop-daemon
}

Push-Location $projectRoot
try {
    & $node $hvigor --mode module `
        -p module=entry@default `
        -p product=default `
        -p requiredDeviceType=phone `
        assembleHap --analyze=normal --parallel --incremental --daemon
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
