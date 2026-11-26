# Pulls series from the FRED API and writes data/series.json (run daily by GitHub Actions)
$key = $env:FRED_API_KEY
if (-not $key) { throw 'FRED_API_KEY is not set' }
$ids = 'DGS2','DGS10','DGS3MO','T10Y2Y','T10Y3M','DFII10','T10YIE','T5YIFR','BAMLH0A0HYM2','BAMLC0A0CM','NFCI','STLFSI4','VIXCLS','WALCL','WTREGEN','RRPONTSYD','DTWEXBGS','ICSA','UNRATE','CPIAUCSL','GDPNOW','SAHMREALTIME','WEI','USEPUINDXD','DCOILWTICO'
$start = (Get-Date).AddYears(-10).ToString('yyyy-MM-dd')
$out = [ordered]@{}
foreach ($id in $ids) {
  $u = "https://api.stlouisfed.org/fred/series/observations?series_id=$id&api_key=$key&file_type=json&observation_start=$start"
  try {
    $o = (Invoke-RestMethod $u).observations | Where-Object { $_.value -ne '.' }
    $out[$id] = [ordered]@{ t = @($o | ForEach-Object { $_.date }); v = @($o | ForEach-Object { [double]$_.value }) }
  } catch { Write-Warning "$id failed: $_" }
  Start-Sleep -Milliseconds 300
}
New-Item -ItemType Directory -Force data | Out-Null
([ordered]@{ updated = (Get-Date).ToUniversalTime().ToString('o'); series = $out } | ConvertTo-Json -Depth 6 -Compress) | Set-Content data/series.json -Encoding utf8
