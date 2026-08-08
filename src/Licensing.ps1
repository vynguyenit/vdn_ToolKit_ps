# Licensing & Activation functions for vdn_ToolKit

function Get-WindowsLicenseInfo {
    Write-Log "Dang lay thong tin ban quyen Windows..." "INFO"
    try {
        $output = & slmgr /dli 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Loi khi doc ban quyen Windows." "ERROR"
            return
        }
        $lines = $output -split "`r`n"
        $status = "Khong xac dinh"
        $edition = ""
        $licenseType = ""
        $key = ""
        foreach ($line in $lines) {
            if ($line -match "Name:\s*(.+)") { $edition = $matches[1] }
            if ($line -match "Description:\s*(.+)") { $licenseType = $matches[1] }
            if ($line -match "License Status:\s*(.+)") { $status = $matches[1] }
            if ($line -match "Partial Product Key:\s*(.+)") { $key = $matches[1] }
        }
        Write-Host ""
        Write-Host "  Edition: $edition" -ForegroundColor Cyan
        Write-Host "  Trang thai: $status" -ForegroundColor Cyan
        Write-Host "  Loai license: $licenseType" -ForegroundColor Cyan
        Write-Host "  Key cuoi: $key" -ForegroundColor Cyan
        Write-Host "`n--- Chi tiet ---"
        Write-Host $output -ForegroundColor DarkGray
    } catch {
        Write-Log "Loi ngoai le khi lay thong tin ban quyen Windows: $_" "ERROR"
    }
}

function Get-OfficeLicenseInfo {
    $officePaths = @(
        @{path="$env:SystemDrive\Program Files\Microsoft Office\Office14\ospp.vbs"; version="Office 2010"},
        @{path="$env:SystemDrive\Program Files (x86)\Microsoft Office\Office14\ospp.vbs"; version="Office 2010"},
        @{path="$env:SystemDrive\Program Files\Microsoft Office\Office15\ospp.vbs"; version="Office 2013"},
        @{path="$env:SystemDrive\Program Files (x86)\Microsoft Office\Office15\ospp.vbs"; version="Office 2013"},
        @{path="$env:SystemDrive\Program Files\Microsoft Office\Office16\ospp.vbs"; version="Office 2016/2019/2021/365"},
        @{path="$env:SystemDrive\Program Files (x86)\Microsoft Office\Office16\ospp.vbs"; version="Office 2016/2019/2021/365"},
        @{path="$env:SystemDrive\Program Files\Microsoft Office\Office19\ospp.vbs"; version="Office 2019"},
        @{path="$env:SystemDrive\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"; version="Office 2019"}
    )
    $found = $false
    Write-Log "Dang lay thong tin ban quyen Office..." "INFO"
    foreach ($item in $officePaths) {
        $path = $item.path
        $version = $item.version
        if (Test-Path $path) {
            $found = $true
            try {
                $output = & cscript //nologo $path /dstatus 2>&1 | Out-String
                $lines = $output -split "`r`n"
                $product = ""; $status = ""; $key = ""
                foreach ($line in $lines) {
                    if ($line -match "PRODUCT ID:\s*(.+)") { $product = $matches[1] }
                    if ($line -match "LICENSE STATUS:\s*(.+)") { $status = $matches[1] }
                    if ($line -match "Last 5 characters:\s*(.+)") { $key = $matches[1] }
                }
                Write-Host "`n--- $version ($path) ---" -ForegroundColor Cyan
                if ($product) { Write-Host "  Product: $product" }
                if ($status) { Write-Host "  Trang thai: $status" }
                if ($key) { Write-Host "  Key cuoi: $key" }
                Write-Host "`n--- Chi tiet ---"
                Write-Host $output -ForegroundColor DarkGray
            } catch {
                Write-Log "Loi khi doc $path : $_" "ERROR"
            }
        }
    }
    if (-not $found) {
        Write-Log "Khong tim thay ban cai Office MSI. Kiem tra Office ClickToRun..." "INFO"
        $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        if (Test-Path $regPath) {
            try {
                $product = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).ProductReleaseIds
                Write-Host "  Office 365/Click-to-Run: $product" -ForegroundColor Cyan
            } catch {
                Write-Log "Khong the truy cap registry Office ClickToRun." "WARN"
            }
        } else {
            Write-Log "Khong tim thay thong tin Office tren he thong." "WARN"
        }
    }
}

function Activate-Windows {
    $key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
    Write-Log "Dang thiet lap khoa san pham Windows: $key" "INFO"
    try {
        $out1 = & slmgr /ipk $key 2>&1 | Out-String
        Write-Host $out1 -ForegroundColor Gray
        Write-Log "Dang ket noi va kich hoat voi KMS server..." "INFO"
        $out2 = & slmgr /ato 2>&1 | Out-String
        Write-Host $out2 -ForegroundColor Gray
        if ($LASTEXITCODE -eq 0 -or $out2 -match "successfully" -or $out2 -match "thanh cong") {
            Write-Log "Kich hoat Windows thanh cong!" "SUCCESS"
        } else {
            Write-Log "Kich hoat Windows that bai. Vui long kiem tra ket noi mang va quyen admin." "ERROR"
        }
    } catch {
        Write-Log "Loi trong qua trinh kich hoat Windows: $_" "ERROR"
    }
}

function Activate-Office {
    $key = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
    $officePaths = @(
        "$env:SystemDrive\Program Files\Microsoft Office\Office14\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office14\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office15\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office15\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office16\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office19\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"
    )
    $found = $false
    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            $found = $true
            Write-Log "Phat hien Office tai $path" "INFO"
            try {
                Write-Log "Dang nhap khoa san pham KMS Office..." "INFO"
                $out1 = & cscript //nologo $path /inpkey:$key 2>&1 | Out-String
                Write-Host $out1 -ForegroundColor Gray
                Write-Log "Dang kich hoat Office..." "INFO"
                $out2 = & cscript //nologo $path /act 2>&1 | Out-String
                Write-Host $out2 -ForegroundColor Gray
                if ($out2 -match "successful" -or $out2 -match "thanh cong") {
                    Write-Log "Kich hoat Office tai $path thanh cong!" "SUCCESS"
                } else {
                    Write-Log "Kich hoat Office tai $path khong thanh cong." "WARN"
                }
            } catch {
                Write-Log "Loi khi thao tac voi $path : $_" "ERROR"
            }
        }
    }
    if (-not $found) {
        Write-Log "Khong tim thay thu muc cai dat Office phu hop de kich hoat KMS." "ERROR"
    }
}

function Remove-WindowsLicense {
    Write-Log "Dang go khoa san pham Windows..." "INFO"
    try {
        $out1 = & slmgr /upk 2>&1 | Out-String
        Write-Host $out1 -ForegroundColor Gray
        Write-Log "Dang xoa khoa san pham khoi registry..." "INFO"
        $out2 = & slmgr /cpky 2>&1 | Out-String
        Write-Host $out2 -ForegroundColor Gray
        Write-Log "Da xoa ban quyen Windows khoi he thong." "SUCCESS"
    } catch {
        Write-Log "Loi khi xoa ban quyen Windows: $_" "ERROR"
    }
}

function Remove-OfficeLicense {
    $officePaths = @(
        "$env:SystemDrive\Program Files\Microsoft Office\Office14\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office14\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office15\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office15\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office16\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
        "$env:SystemDrive\Program Files\Microsoft Office\Office19\ospp.vbs",
        "$env:SystemDrive\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"
    )
    $found = $false
    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            $found = $true
            Write-Log "Dang quet key Office tai $path ..." "INFO"
            try {
                $output = & cscript //nologo $path /dstatus 2>&1 | Out-String
                $lines = $output -split "`r`n"
                $keys = @()
                foreach ($line in $lines) {
                    if ($line -match "Last 5 characters:\s*(.+)") {
                        $keys += $matches[1].Trim()
                    }
                }
                if ($keys.Count -eq 0) {
                    Write-Log "Khong tim thay khoa Office nao de go bo tai day." "INFO"
                    continue
                }
                foreach ($key in $keys) {
                    if ($key) {
                        Write-Log "Dang go khoa Office co 5 ky tu cuoi: $key" "INFO"
                        $out = & cscript //nologo $path /unpkey:$key 2>&1 | Out-String
                        Write-Host $out -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Log "Loi khi go khoa Office tai $path : $_" "ERROR"
            }
        }
    }
    if ($found) {
        Write-Log "Da hoan thanh xoa khoa san pham Office." "SUCCESS"
    } else {
        Write-Log "Khong tim thay phien ban Office hop le de go khoa." "WARN"
    }
}
