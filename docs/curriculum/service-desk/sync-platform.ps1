# Mirror chatdox-platform's request/ folder (execution-tracking copies of
# service-desk tickets, plus any curriculum-side handoff memos) into a local,
# gitignored folder here so Claudox can read them without leaving this repo.
# Source of truth stays service-desk/requests/*.md in THIS repo — this is a
# read-only snapshot for reference, never edited or committed directly.
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot "..\..\chatdox-platform\request")
)

$ErrorActionPreference = "Stop"
Push-Location -Path $PSScriptRoot
try {
    $resolvedSource = Resolve-Path -Path $SourcePath -ErrorAction SilentlyContinue
    if (-not $resolvedSource) {
        Write-Error "소스 폴더를 찾을 수 없음: $SourcePath (chatdox-platform이 옆에 clone되어 있는지 확인, 또는 -SourcePath로 직접 지정)"
        exit 1
    }

    $dest = Join-Path $PSScriptRoot "_platform_sync"
    if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Copy-Item -Path (Join-Path $resolvedSource "*") -Destination $dest -Recurse -Force

    $count = (Get-ChildItem -Path $dest -File).Count
    Write-Output "Synced $count file(s) from $resolvedSource to $dest"
}
finally {
    Pop-Location
}
