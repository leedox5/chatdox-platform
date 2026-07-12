# Regenerate dashboard.md by scanning requests/*.md
$ErrorActionPreference = "Stop"
Push-Location -Path $PSScriptRoot
try {
    $counts = @{ "New" = 0; "In Progress" = 0; "Completed" = 0; "Confirmed" = 0 }
    $rows = @()

    $files = Get-ChildItem -Path "requests" -Filter "????.md" -File | Sort-Object Name
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Encoding UTF8
        $id      = ($content | Select-String "ID :"      | Select-Object -First 1) -replace "^\s*ID\s*:\s*", ""
        $date    = ($content | Select-String "Date :"    | Select-Object -First 1) -replace "^\s*Date\s*:\s*", ""
        $subject = ($content | Select-String "Subject :" | Select-Object -First 1) -replace "^\s*Subject\s*:\s*", ""
        $status  = ($content | Select-String "Status :"  | Select-Object -First 1) -replace "^\s*Status\s*:\s*", ""

        if ($counts.ContainsKey($status)) { $counts[$status]++ }
        $rows += "| $id | $date | $subject | $status |"
    }

    $total = $files.Count
    $lines = @(
        "# 종합현황",
        "",
        "요청 $total · 신규 $($counts['New']) · 진행중 $($counts['In Progress']) · 완료 $($counts['Completed']) · 확인 $($counts['Confirmed'])",
        "",
        "| ID | Date | Subject | Status |",
        "|---|---|---|---|"
    ) + $rows + @("", "---", "", "*새 요청이 생기거나 상태가 바뀌면 이 표도 같이 갱신한다.*")

    $lines | Set-Content -Encoding utf8 dashboard.md
    Write-Output "dashboard.md regenerated ($total requests)"
}
finally {
    Pop-Location
}
