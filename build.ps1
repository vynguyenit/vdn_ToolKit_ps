# build.ps1 - Ghep cac module tu src/ thanh script phan phoi vdn_ToolKit.ps1

$srcFiles = @(
    "src/00_Params.ps1",
    "src/Core.ps1",
    "src/Licensing.ps1",
    "src/Software.ps1",
    "src/Optimizer.ps1",
    "src/Printer.ps1",
    "src/Main.ps1"
)

$outputFile = "vdn_ToolKit.ps1"
Write-Host "Dang ghep cac file trong src/ vao $outputFile..." -ForegroundColor Cyan

$mergedContent = @()
foreach ($file in $srcFiles) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (-not (Test-Path $fullPath)) {
        Write-Error "Khong tim thay file module: $fullPath"
        exit 1
    }
    Write-Host "  -> Dang doc $file" -ForegroundColor Gray
    $content = Get-Content -Path $fullPath -Raw
    $mergedContent += $content
}

$finalCode = $mergedContent -join "`r`n`r`n"

# Write final file in UTF-8
$outputPath = Join-Path $PSScriptRoot $outputFile
$finalCode | Out-File -FilePath $outputPath -Encoding UTF8 -Force
Write-Host "Ghi file thanh cong: $outputPath" -ForegroundColor Green

# Validate syntax
Write-Host "Dang kiem tra loi cu phap..." -ForegroundColor Cyan
$errors = $null
$tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($outputPath, [ref]$tokens, [ref]$errors)

if ($errors) {
    Write-Error "Phat hien loi cu phap trong file ket qua:"
    foreach ($err in $errors) {
        Write-Error "  Dong $($err.Extent.StartLineNumber): $($err.Message)"
    }
    exit 1
} else {
    Write-Host "Xac minh hoan tat. File $outputFile hoat dong tot!" -ForegroundColor Green
}
