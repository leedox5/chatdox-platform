# Create a new service-desk request from 01_new/_FORM.md with the next ID.
$ErrorActionPreference = "Stop"
Push-Location -Path $PSScriptRoot
try {
    $ids = Get-ChildItem -Path "01_new","02_in_progress","03_completed" -Filter "????.md" -File -ErrorAction SilentlyContinue |
        ForEach-Object { [int]($_.BaseName) }
    $max = if ($ids) { [int]($ids | Measure-Object -Maximum).Maximum } else { 0 }
    $next = "{0:D4}" -f ($max + 1)
    $dest = Join-Path "01_new" "$next.md"

    if (Test-Path $dest) {
        Write-Error "이미 존재함: $dest"
        exit 1
    }

    $today = Get-Date -Format "yyyy.MM.dd"
    (Get-Content "01_new/_FORM.md") `
        -replace "ID : NNNN", "ID : $next" `
        -replace "Date : YYYY.MM.DD", "Date : $today" |
        Set-Content -Encoding utf8 $dest

    Write-Output "Created $dest"
}
finally {
    Pop-Location
}
