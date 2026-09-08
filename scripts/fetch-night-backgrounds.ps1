param([switch]$Download, [switch]$Missing, [switch]$Refresh, [switch]$GenerateMapping)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$headers = @{'User-Agent'='harmony-weather/1.0 (open source weather application)'}
$names = [ordered]@{'101010100'='Beijing';'101020100'='Shanghai';'101280101'='Guangzhou';'101280601'='Shenzhen';'101210101'='Hangzhou';'101190101'='Nanjing';'101200101'='Wuhan';'101270101'='Chengdu';'101110101'='Xian';'101040100'='Chongqing';'101030100'='Tianjin';'101190401'='Suzhou';'101250101'='Changsha';'101120201'='Qingdao';'101070201'='Dalian'}
$manifest = Join-Path $root 'design/city-night-candidates.json'
if (!$Download -and !$GenerateMapping) {
  $records = if ($Missing -and (Test-Path -LiteralPath $manifest)) { @(Get-Content -Raw -Encoding UTF8 $manifest | ConvertFrom-Json | Where-Object { $_.photos[0].url }) } else { @() }
  foreach ($id in $names.Keys) {
    $name = $names[$id]
    if ($Missing -and ($records | Where-Object { $_.id -eq $id })) { continue }
    $term = if ($name -eq 'Xian') { '"Xi''an" night' } elseif ($Missing) { "intitle:$name night" } else { "$name skyline night" }
    $url = 'https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=' + [uri]::EscapeDataString($term) + '&gsrnamespace=6&gsrlimit=5&prop=imageinfo&iiprop=url%7Cextmetadata&iiurlwidth=1280&format=json&formatversion=2'
    try {
      $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 25
      $photos = @($response.query.pages | Sort-Object index | ForEach-Object {
        $info=$_.imageinfo[0]; $meta=$info.extmetadata
        [pscustomobject]@{title=$_.title;url=($info.thumburl -split '\?')[0];original=$info.url;page=$info.descriptionurl;license=$meta.LicenseShortName.value;licenseUrl=$meta.LicenseUrl.value;author=([regex]::Replace($meta.Artist.value,'<[^>]+>','')).Trim();description=([regex]::Replace($meta.ImageDescription.value,'<[^>]+>','')).Trim()}
      })
      $records += [pscustomobject]@{id=$id;name=$name;photos=$photos}
      Write-Output "$name : $($photos.Count) candidates"
    } catch { Write-Warning "$name : $($_.Exception.Message)" }
    Start-Sleep -Seconds 3
  }
  $records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifest -Encoding utf8
} elseif ($Download) {
  Add-Type -AssemblyName System.Drawing
  $records = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'design/city-night-selected.json') | ConvertFrom-Json
  foreach ($record in $records) {
    if ($record.id -notmatch '^\d{9}$') { throw 'Invalid city ID in photo manifest' }
    $ext = if ($record.url -match '\.png$') { 'png' } else { 'jpg' }
    $dest = Join-Path $root "entry/src/main/resources/base/media/city_night_$($record.id).$ext"
    if (!$Refresh -and (Test-Path -LiteralPath $dest)) { continue }
    $temporary = "$dest.download"
    try {
      Invoke-WebRequest -Uri $record.url -Headers $headers -OutFile $temporary -TimeoutSec 35
      $picture = [System.Drawing.Image]::FromFile($temporary)
      $picture.Dispose()
      Move-Item -LiteralPath $temporary -Destination $dest -Force
      Write-Output "$($record.name) : downloaded"
    } catch { Write-Warning "$($record.name) : $($_.Exception.Message)" }
    finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
    Start-Sleep -Milliseconds 500
  }
}

if ($Download -or $GenerateMapping) {
  Add-Type -AssemblyName System.Drawing
  $records = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'design/city-night-selected.json') | ConvertFrom-Json
  $lines = @('import { BundledCityBackground } from ''./BundledCityBackgrounds''', '', '// Generated from reviewed city-night-selected.json and downloaded photo dimensions.', 'export class NightCityBackgrounds {', '  static resolve(cityId: string): BundledCityBackground | null {', '    switch (cityId) {')
  foreach ($record in $records) {
    $id = $record.id
    if ($id -notmatch '^\d{9}$') { throw 'Invalid city ID in photo manifest' }
    $file = Get-ChildItem -LiteralPath (Join-Path $root 'entry/src/main/resources/base/media') -Filter "city_night_$id.*" | Select-Object -First 1
    if (!$file) { continue }
    $picture = [System.Drawing.Image]::FromFile($file.FullName)
    $ratio = ([double]$picture.Width / $picture.Height).ToString('0.000000', [cultureinfo]::InvariantCulture)
    $picture.Dispose()
    $credit = ($record.author + ' / ' + $record.license).Replace('\', '\\').Replace("'", "\'").Replace("`n", ' ').Replace("`r", '')
    $src = $record.page.Replace("'", "\'")
    $lic = if ($record.licenseUrl) { $record.licenseUrl.Replace("'", "\'") } else { '' }
    $resource = '$r(''app.media.city_night_{0}'')' -f $id
    $lines += "      case '$id': return new BundledCityBackground($resource, '$credit', true, $ratio, '$src', '$lic')"
  }
  $lines += @('      default: return null', '    }', '  }', '}')
  $lines | Set-Content -LiteralPath (Join-Path $root 'entry/src/main/ets/theme/NightCityBackgrounds.ets') -Encoding utf8
}
