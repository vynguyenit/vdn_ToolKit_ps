# Main execution controller for vdn_ToolKit

function Get-SystemInfo {
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        
        $cpu = "Khong xac dinh"
        $cpuObj = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        if ($cpuObj) {
            if ($cpuObj -is [array]) {
                $cpu = $cpuObj[0].Name
            } else {
                $cpu = $cpuObj.Name
            }
        }
        
        $ram = 0
        if ($cs.TotalPhysicalMemory) {
            $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        }
        
        $diskInfo = ""
        $disk = Get-PSDrive -Name C -ErrorAction SilentlyContinue
        if ($disk) {
            $usedGb = [math]::Round($disk.Used/1GB, 2)
            $freeGb = [math]::Round($disk.Free/1GB, 2)
            $totalGb = [math]::Round(($disk.Used + $disk.Free)/1GB, 2)
            $diskInfo = "$totalGb GB (Con trong $freeGb GB)"
        } else {
            $diskInfo = "Khong xac dinh"
        }
        
        Write-Host ""
        Write-Host "  Ten may: $($cs.Name)" -ForegroundColor Cyan
        Write-Host "  Domain: $($cs.Domain)" -ForegroundColor Cyan
        Write-Host "  He dieu hanh: $($os.Caption) (Build $($os.BuildNumber))" -ForegroundColor Cyan
        Write-Host "  CPU: $cpu" -ForegroundColor Cyan
        Write-Host "  RAM: $ram GB" -ForegroundColor Cyan
        Write-Host "  O dia C: $diskInfo" -ForegroundColor Cyan
    } catch {
        Write-Log "Loi khi lay thong tin he thong: $_" "ERROR"
    }
}

# Main Entry Point
Confirm-AdminPrivilege
Download-Configuration

if ($Action) {
    Write-Log "Dang chay che do Command Line (CLI) voi Action: $Action" "INFO"
    switch ($Action) {
        "SysInfo" {
            Get-SystemInfo
        }
        "WinLicense" {
            Get-WindowsLicenseInfo
        }
        "OfficeLicense" {
            Get-OfficeLicenseInfo
        }
        "ActivateWin" {
            if ($Silent -or (Read-Host "Kich hoat Windows? (Y/N)") -eq "Y") {
                Activate-Windows
            }
        }
        "ActivateOffice" {
            if ($Silent -or (Read-Host "Kich hoat Office? (Y/N)") -eq "Y") {
                Activate-Office
            }
        }
        "RemoveWinLic" {
            if ($Silent -or (Read-Host "Go bo ban quyen Windows? (Y/N)") -eq "Y") {
                Remove-WindowsLicense
            }
        }
        "RemoveOfficeLic" {
            if ($Silent -or (Read-Host "Go bo ban quyen Office? (Y/N)") -eq "Y") {
                Remove-OfficeLicense
            }
        }
        "InstallApps" {
            if ($Apps) {
                Install-SelectedSoftware -selections $Apps
            } else {
                Write-Log "Thieu tham so -Apps de cai dat." "ERROR"
            }
        }
        "Optimize" {
            if ($TweakOption) {
                Invoke-SystemTweaks -option $TweakOption -Interactive (-not $Silent)
            } else {
                Invoke-SystemTweaks -option "9" -Interactive (-not $Silent)
            }
        }
        "CleanCarbonBlack" {
            Clean-CarbonBlackStore
        }
        "CleanPrinters" {
            if ($Silent -or (Read-Host "Xoa tat ca may in? (Y/N)") -eq "Y") {
                Remove-AllPrinters
            }
        }
    }
    
    # Cleanup temp folder before exiting
    Remove-Item -Path $toolkitDir -Recurse -Force -ErrorAction SilentlyContinue
    exit
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "         vdn ToolKit - He thong & Ban quyen" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [1] Thong tin he thong"
    Write-Host "  [2] Ban quyen Windows"
    Write-Host "  [3] Ban quyen Office"
    Write-Host "  [4] Kich hoat Windows (KMS)"
    Write-Host "  [5] Kich hoat Office (KMS)"
    Write-Host "  [6] Xoa ban quyen Windows (Nguy hiem)"
    Write-Host "  [7] Xoa ban quyen Office (Nguy hiem)"
    Write-Host ""
    Write-Host "  [8] Cai dat phan mem (winget / Direct URL)"
    Write-Host "  [9] Toi uu he thong (Optimizer)"
    Write-Host ""
    Write-Host "  [A] Quan ly may in"
    Write-Host "  [H] Huong dan su dung"
    Write-Host "  [0] Thoat"
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    
    $choice = Read-Host "Chon chuc nang [1-9, A, H, 0]"

    switch ($choice) {
        "1" { 
            Clear-Host
            Write-Host "=== THONG TIN HE THONG ===" -ForegroundColor Green
            Get-SystemInfo
            Read-Host "`nNhan Enter de tiep tuc" 
        }
        "2" { 
            Clear-Host
            Write-Host "=== BAN QUYEN WINDOWS ===" -ForegroundColor Green
            Get-WindowsLicenseInfo
            Read-Host "`nNhan Enter de tiep tuc" 
        }
        "3" { 
            Clear-Host
            Write-Host "=== BAN QUYEN OFFICE ===" -ForegroundColor Green
            Get-OfficeLicenseInfo
            Read-Host "`nNhan Enter de tiep tuc" 
        }
        "4" { 
            Clear-Host
            Write-Host "=== KICH HOAT WINDOWS (KMS) ===" -ForegroundColor Green
            $confirm = Read-Host "Ban co muon tiep tuc kich hoat Windows? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { 
                Activate-Windows 
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "5" {
            Clear-Host
            Write-Host "=== KICH HOAT OFFICE (KMS) ===" -ForegroundColor Green
            $confirm = Read-Host "Ban co muon tiep tuc kich hoat Office? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { 
                Activate-Office 
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "6" {
            Clear-Host
            Write-Host "=== XOA BAN QUYEN WINDOWS (NGUY HIEM) ===" -ForegroundColor Yellow
            Write-Log "CANH BAO: Hanh dong nay se xoa key Windows hien tai khoi may." "WARN"
            $confirm = Read-Host "Ban co thuc su chac chan? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { 
                Remove-WindowsLicense 
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "7" {
            Clear-Host
            Write-Host "=== XOA BAN QUYEN OFFICE (NGUY HIEM) ===" -ForegroundColor Yellow
            Write-Log "CANH BAO: Hanh dong nay se go cac key Office dang co tren may." "WARN"
            $confirm = Read-Host "Ban co thuc su chac chan? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { 
                Remove-OfficeLicense 
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "8" {
            Clear-Host
            Write-Host "=== CAI DAT PHAN MEM ===" -ForegroundColor Green
            Show-SoftwareList
            $selections = Read-Host "`nNhap so thu tu phan mem can cai (cach nhau boi khoang trang, vi du: 1 3 10)"
            if (-not [string]::IsNullOrWhiteSpace($selections)) {
                Install-SelectedSoftware -selections $selections
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "9" {
            Clear-Host
            Write-Host "=== TOI UU HE THONG (OPTIMIZER) ===" -ForegroundColor Green
            Write-Host ""
            Write-Host "  [1] Don rac he thong (Temp, Prefetch, Recent)"
            Write-Host "  [2] Toi uu mang (Flush DNS, Reset Winsock, Reset IP)"
            Write-Host "  [3] Toi uu hieu suat (High Performance, Menu delay)"
            Write-Host "  [4] Tat dich vu khong can thiet (SysMain, DiagTrack, WSearch)"
            Write-Host "  [5] Xoa cache Windows Update"
            Write-Host "  [6] Toi uu o dia (SSD TRIM / HDD NTFS)"
            Write-Host "  [7] Tat Hibernate"
            Write-Host "  [8] Don dep thu muc CarbonBlack Store"
            Write-Host "  [9] THUC HIEN TAT CA TOI UU (An toan)"
            Write-Host "  [0] Quay lai"
            Write-Host ""
            $tweakChoice = Read-Host "Chon chuc nang [1-9 hoac 0]"
            if ($tweakChoice -ne "0" -and -not [string]::IsNullOrWhiteSpace($tweakChoice)) {
                Invoke-SystemTweaks -option $tweakChoice -Interactive $true
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "A" {
            Clear-Host
            Write-Host "=== QUAN LY MAY IN ===" -ForegroundColor Green
            Write-Host "  [1] Xoa sach may in nguoi dung (giu lai driver)"
            Write-Host "  [2] Mo Print Management (Quan ly may in he thong)"
            Write-Host "  [0] Quay lai"
            Write-Host ""
            $printerChoice = Read-Host "Chon chuc nang [1, 2 hoac 0]"
            if ($printerChoice -eq "1") {
                $confirm = Read-Host "Ban co thuc su muon xoa tat ca may in nguoi dung? (Y/N)"
                if ($confirm -eq "Y" -or $confirm -eq "y") { 
                    Remove-AllPrinters 
                }
            } elseif ($printerChoice -eq "2") {
                Write-Log "Dang mo Print Management..." "INFO"
                try {
                    Start-Process "printmanagement.msc"
                } catch {
                    Write-Log "Khong the mo printmanagement.msc: $_" "ERROR"
                }
            }
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "H" {
            Clear-Host
            Write-Host "=== HUONG DAN SU DUNG ===" -ForegroundColor Green
            Write-Host ""
            Write-Host "vdn ToolKit - Bo cong cu quan tri Windows chuyen nghiep."
            Write-Host ""
            Write-Host "CAC TINH NANG CHINH:"
            Write-Host "  1. Hien thi thong tin he thong va thiet bi phan cung."
            Write-Host "  2. Hien thi chi tiet thong tin ban quyen cua Windows."
            Write-Host "  3. Hien thi chi tiet thong tin ban quyen cua Office (2010 - 365)."
            Write-Host "  4. Kich hoat Windows bang khoa KMS mac dinh."
            Write-Host "  5. Kich hoat Office bang khoa KMS mac dinh."
            Write-Host "  6. Go bo khoa Windows khoi registry va he thong."
            Write-Host "  7. Go bo cac khoa Office dang luu tru."
            Write-Host "  8. Cai dat hang loat cac phan mem qua winget hoac link truc tiep."
            Write-Host "  9. Toi uu hoa toan dien he thong (bao gom don rac, do tre menu, TRIM SSD, "
            Write-Host "     va don dep CarbonBlack Store tai C:\Windows\CarbonBlack\Store)."
            Write-Host "  A. Xoa cac may in khong su dung va mo Print Management."
            Write-Host "  0. Thoat khoi bo cong cu."
            Write-Host ""
            Write-Host "CHE DO CLI (CHAY DONG LENH):"
            Write-Host "  Co the chay khong can menu bang cach truyen tham so:"
            Write-Host "  powershell -File vdn_ToolKit.ps1 -Action <TenAction> [-Apps '<Indices>'] [-TweakOption <Option>] [-Silent]"
            Write-Host "  Vi du:"
            Write-Host "    - Kiem tra ban quyen Windows:   -Action WinLicense"
            Write-Host "    - Don dep CarbonBlack Store:    -Action CleanCarbonBlack"
            Write-Host "    - Cai dat Chrome va 7-Zip:     -Action InstallApps -Apps '1 2'"
            Write-Host "    - Toi uu he thong silent:       -Action Optimize -TweakOption 9 -Silent"
            Read-Host "`nNhan Enter de tiep tuc"
        }
        "0" { 
            Write-Log "Dang don dep thu muc tam..." "INFO"
            Remove-Item -Path $toolkitDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Cam on da su dung vdn ToolKit. Tam biet!" "SUCCESS"
            break
        }
        default { 
            Write-Log "Lua chon khong hop le. Vui long chon lai." "WARN"
            Start-Sleep -Seconds 1 
        }
    }
} while ($choice -ne "0")
