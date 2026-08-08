<#
.SYNOPSIS
    vdn ToolKit - Bo cong cu quan tri he thong Windows chuyen nghiep
.DESCRIPTION
    Hien thi thong tin, kiem tra ban quyen, kich hoat Windows/Office,
    cai dat phan mem, toi uu he thong, quan ly may in.
    Chay voi quyen Administrator. Ho tro ca giao dien menu va che do dong lenh (CLI).
.PARAMETER Action
    Hanh dong can thuc hien (SysInfo, WinLicense, OfficeLicense, ActivateWin, ActivateOffice, RemoveWinLic, RemoveOfficeLic, InstallApps, Optimize, CleanCarbonBlack, CleanPrinters).
.PARAMETER Apps
    Danh sach index phan mem can cai dat (cach nhau boi khoang trang), e.g. "1 3 5"
.PARAMETER TweakOption
    Lua chon toi uu (1-9), e.g. "8" de don dep CarbonBlack Store.
.PARAMETER Silent
    Chay che do khong hien thi hoi xac nhan.
#>

[CmdletBinding()]
param(
    [ValidateSet("SysInfo", "WinLicense", "OfficeLicense", "ActivateWin", "ActivateOffice", "RemoveWinLic", "RemoveOfficeLic", "InstallApps", "Optimize", "CleanCarbonBlack", "CleanPrinters")]
    [string]$Action,

    [string]$Apps,

    [ValidateSet("1", "2", "3", "4", "5", "6", "7", "8", "9")]
    [string]$TweakOption,

    [switch]$Silent
)


# Core functions for vdn_ToolKit

#region Logging
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $color = switch ($Level) {
        "INFO"    { "Gray" }
        "SUCCESS" { "Green" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}
#endregion

#region Elevation Check
function Confirm-AdminPrivilege {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "Yeu cau quyen quan tri vien (Administrator). Dang khoi chay lai..." "WARN"
        $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        exit
    }
}
#endregion

#region Config & Workspace
$baseDir = Join-Path $env:USERPROFILE "tempkit"
if (-not (Test-Path $baseDir)) { New-Item -ItemType Directory -Path $baseDir -Force | Out-Null }
$toolkitDir = Join-Path $baseDir "vdn_ToolKit_$([System.Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $toolkitDir -Force | Out-Null

$repoUrl = "https://raw.githubusercontent.com/vynguyenit/vnd_ToolKit_ps/main"
$configUrl = "$repoUrl/config/software.json"
$configPath = Join-Path $toolkitDir "software.json"

function Get-AppList {
    if (Test-Path $configPath) {
        try {
            $json = Get-Content $configPath -Raw -ErrorAction Stop | ConvertFrom-Json
            return $json.apps
        } catch {
            Write-Log "Loi khi phan tich file cau hinh: $_. Dang dung cau hinh mac dinh." "WARN"
        }
    }
    return @(
        [PSCustomObject]@{name="7-Zip"; id="7zip.7zip"; url=""},
        [PSCustomObject]@{name="Google Chrome"; id="Google.Chrome"; url=""},
        [PSCustomObject]@{name="Microsoft Edge"; id="Microsoft.Edge"; url=""},
        [PSCustomObject]@{name="LibreOffice"; id="LibreOffice.LibreOffice"; url=""},
        [PSCustomObject]@{name="OnlyOffice"; id="ONLYOFFICE.ONLYOFFICE"; url=""},
        [PSCustomObject]@{name=".NET Runtime 4.8"; id="Microsoft.DotNet.Runtime.4_8"; url=""},
        [PSCustomObject]@{name=".NET Runtime 6"; id="Microsoft.DotNet.Runtime.6"; url=""},
        [PSCustomObject]@{name=".NET Runtime 8"; id="Microsoft.DotNet.Runtime.8"; url=""},
        [PSCustomObject]@{name="Notepad++"; id="Notepad++.Notepad++"; url=""},
        [PSCustomObject]@{name="Telegram"; id="Telegram.TelegramDesktop"; url=""},
        [PSCustomObject]@{name="Zalo"; id="Zalo.Zalo"; url=""},
        [PSCustomObject]@{name="KillerPDF"; id=""; url="https://download.killerpdf.com/KillerPDFSetup.exe"}
    )
}

function Download-Configuration {
    try {
        Invoke-WebRequest -Uri $configUrl -OutFile $configPath -ErrorAction Stop -TimeoutSec 10
        Write-Log "Da tai file cau hinh phan mem moi nhat." "SUCCESS"
    } catch {
        Write-Log "Khong tai duoc cau hinh phan mem tu internet. Su dung danh sach mac dinh." "WARN"
        $defaultJson = @'
{
  "apps": [
    {"name":"7-Zip","id":"7zip.7zip","url":""},
    {"name":"Google Chrome","id":"Google.Chrome","url":""},
    {"name":"Microsoft Edge","id":"Microsoft.Edge","url":""},
    {"name":"LibreOffice","id":"LibreOffice.LibreOffice","url":""},
    {"name":"OnlyOffice","id":"ONLYOFFICE.ONLYOFFICE","url":""},
    {"name":".NET Runtime 4.8","id":"Microsoft.DotNet.Runtime.4_8","url":""},
    {"name":".NET Runtime 6","id":"Microsoft.DotNet.Runtime.6","url":""},
    {"name":".NET Runtime 8","id":"Microsoft.DotNet.Runtime.8","url":""},
    {"name":"Notepad++","id":"Notepad++.Notepad++","url":""},
    {"name":"Telegram","id":"Telegram.TelegramDesktop","url":""},
    {"name":"Zalo","id":"Zalo.Zalo","url":""},
    {"name":"KillerPDF","id":"","url":"https://download.killerpdf.com/KillerPDFSetup.exe"}
  ]
}
'@
        $defaultJson | Out-File -FilePath $configPath -Encoding UTF8 -Force
    }
}
#endregion


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


# Software Installer functions for vdn_ToolKit

function Show-SoftwareList {
    $appList = Get-AppList
    $i = 1
    Write-Host "`n=== DANH SACH PHAN MEM CO SAN ===" -ForegroundColor Cyan
    foreach ($app in $appList) {
        Write-Host "  [$i] $($app.name)"
        $i++
    }
}

function Install-SelectedSoftware {
    param(
        [Parameter(Mandatory=$true)]
        [string]$selections
    )
    $appList = Get-AppList
    $selectedIndexes = $selections -split "\s+"
    Write-Log "Bat dau qua trinh cai dat phan mem da chon..." "INFO"
    
    # Check if winget is available
    $hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
    
    foreach ($idx in $selectedIndexes) {
        if ([string]::IsNullOrWhiteSpace($idx)) {
            continue
        }
        $num = 0
        if (-not [int]::TryParse($idx, [ref]$num)) {
            Write-Log "Lua chon '$idx' khong hop le (phai la so nguyen)." "WARN"
            continue
        }
        if ($num -ge 1 -and $num -le $appList.Count) {
            $app = $appList[$num-1]
            $name = $app.name
            $id = $app.id
            $url = $app.url

            if ($id -and $id -ne "") {
                if (-not $hasWinget) {
                    Write-Log "He thong khong co winget. Khong the cai dat $name qua winget ID." "ERROR"
                    if ($url -and $url -ne "") {
                        Write-Log "Chuyen sang cai dat qua link truc tiep..." "WARN"
                    } else {
                        continue
                    }
                } else {
                    Write-Log "Dang cai dat $name (winget ID: $id)..." "INFO"
                    try {
                        $proc = Start-Process -FilePath "winget" -ArgumentList "install $id --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
                        if ($proc.ExitCode -eq 0) {
                            Write-Log "Cai dat $name thanh cong." "SUCCESS"
                        } else {
                            Write-Log "Cai dat $name that bai (Ma loi: $($proc.ExitCode))." "ERROR"
                        }
                    } catch {
                        Write-Log "Loi xay ra khi chay winget de cai $($name) - $_" "ERROR"
                    }
                    continue
                }
            }
            
            if ($url -and $url -ne "") {
                Write-Log "Dang tai phan mem $name tu link: $url ..." "INFO"
                try {
                    $fileName = [System.IO.Path]::GetFileName($url)
                    if (-not $fileName) { $fileName = "installer.exe" }
                    $installer = Join-Path $env:TEMP $fileName
                    Invoke-WebRequest -Uri $url -OutFile $installer -ErrorAction Stop
                    Write-Log "Tai xuong thanh cong. Dang cai dat silent..." "INFO"
                    
                    # Install silently
                    $proc = Start-Process -FilePath $installer -ArgumentList "/quiet /norestart /S /silent" -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { # 3010 means reboot required but install was successful
                        Write-Log "Cai dat $name thanh cong." "SUCCESS"
                    } else {
                        Write-Log "Cai dat $name that bai (Ma loi: $($proc.ExitCode))." "ERROR"
                    }
                    Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Log "Loi khi tai hoac cai dat $($name) - $_" "ERROR"
                }
            } else {
                Write-Log "Khong co thong tin nguon cai dat (ID winget hoac URL) cho $name." "WARN"
            }
        } else {
            Write-Log "Lua chon '$num' nam ngoai danh sach phan mem." "WARN"
        }
    }
}


# System Tweak and Optimizer functions for vdn_ToolKit

function Clean-SystemTempFiles {
    Write-Log "Dang don rac he thong (Temp, Prefetch, Recent)..." "INFO"
    $exclude = ""
    if ($toolkitDir) {
        $exclude = (Get-Item $toolkitDir -ErrorAction SilentlyContinue).Name
    }
    
    # User Temp
    if (Test-Path $env:TEMP) {
        try {
            Get-ChildItem -Path $env:TEMP -Directory -Exclude $exclude -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $env:TEMP -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    # System Temp
    $sysTemp = Join-Path $env:SystemRoot "Temp"
    if (Test-Path $sysTemp) {
        try {
            Get-ChildItem -Path "$sysTemp\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    # Prefetch
    $prefetch = Join-Path $env:SystemRoot "Prefetch"
    if (Test-Path $prefetch) {
        try {
            Get-ChildItem -Path "$prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    # Recent Files
    $recent = Join-Path $env:APPDATA "Microsoft\Windows\Recent"
    if (Test-Path $recent) {
        try {
            Get-ChildItem -Path "$recent\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    Write-Log "Da don dep rac he thong." "SUCCESS"
}

function Optimize-Network {
    param([bool]$ResetIP = $false)
    Write-Log "Dang lam sach DNS cache..." "INFO"
    try {
        ipconfig /flushdns | Out-Null
        Write-Log "Da xoa cache DNS." "SUCCESS"
    } catch {
        Write-Log "Khong the flush DNS." "WARN"
    }
    
    Write-Log "Dang khoi dong lai WinSock..." "INFO"
    try {
        netsh winsock reset | Out-Null
        Write-Log "Da reset Winsock." "SUCCESS"
    } catch {
        Write-Log "Khong the reset Winsock." "WARN"
    }
    
    if ($ResetIP) {
        Write-Log "Dang khoi dong lai IP Stack..." "INFO"
        try {
            netsh int ip reset | Out-Null
            Write-Log "Da reset IP Stack. Luu y: Can khoi dong lai may de co hieu luc." "SUCCESS"
        } catch {
            Write-Log "Khong the reset IP Stack." "WARN"
        }
    } else {
        Write-Log "Bo qua khoi dong lai IP stack de tranh ngat ket noi mang." "INFO"
    }
}

function Optimize-Performance {
    Write-Log "Dang toi uu hieu suat..." "INFO"
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    try {
        $plans = powercfg -list
        if ($plans -match $highPerfGuid) {
            powercfg -setactive $highPerfGuid
            Write-Log "Da kich hoat so do nguon High Performance." "SUCCESS"
        } else {
            Write-Log "Khong tim thay so do nguon High Performance san co. Dang thiet lap che do tuong duong..." "WARN"
            $null = powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            $null = powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        }
    } catch {
        Write-Log "Khong the thiet lap so do nguon High Performance." "WARN"
    }
    
    try {
        reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f | Out-Null
        Write-Log "Da giam do tre menu ve 0." "SUCCESS"
    } catch {
        Write-Log "Khong the thay doi registry MenuShowDelay: $_" "WARN"
    }
}

function Optimize-Services {
    param([bool]$DisableSearch = $false)
    $services = @("DiagTrack", "SysMain")
    if ($DisableSearch) {
        $services += "WSearch"
    }
    
    foreach ($svcName in $services) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Log "Dang tat va vo hieu hoa dich vu: $svcName ..." "INFO"
            try {
                if ($svc.Status -eq "Running") {
                    Stop-Service -Name $svcName -Force -ErrorAction Stop | Out-Null
                }
                Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop | Out-Null
                Write-Log "Da tat va vo hieu hoa $svcName." "SUCCESS"
            } catch {
                Write-Log "Khong the tat hoac vo hieu hoa $($svcName) - $_" "WARN"
            }
        }
    }
}

function Clean-WindowsUpdateCache {
    Write-Log "Dang xoa cache Windows Update..." "INFO"
    try {
        Write-Log "Dang dung dich vu Windows Update va BITS..." "INFO"
        $null = Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        $null = Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
        
        $updatePath = Join-Path $env:SystemRoot "SoftwareDistribution"
        if (Test-Path $updatePath) {
            Write-Log "Dang xoa thu muc SoftwareDistribution..." "INFO"
            Get-ChildItem -Path "$updatePath\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Log "Dang khoi dong lai dich vu Windows Update va BITS..." "INFO"
        $null = Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        $null = Start-Service -Name bits -ErrorAction SilentlyContinue
        Write-Log "Da xoa cache Windows Update thanh cong." "SUCCESS"
    } catch {
        Write-Log "Gap loi trong luc don cache Windows Update: $_" "ERROR"
    }
}

function Optimize-Drives {
    Write-Log "Dang kiem tra loai o dia he thong..." "INFO"
    try {
        $disk = (Get-Partition -DriveLetter C).DiskNumber
        $media = (Get-PhysicalDisk -DeviceNumber $disk).MediaType
        if ($media -eq "SSD") {
            Write-Log "Phat hien C: la o SSD. Dang chay lenh TRIM..." "INFO"
            Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop | Out-Null
            Write-Log "Chay TRIM cho o SSD thanh cong." "SUCCESS"
        } else {
            Write-Log "Phat hien C: la o HDD (hoac khong xac dinh). Dang toi uu cau hinh NTFS..." "INFO"
            fsutil behavior set disablelastaccess 1 -ErrorAction SilentlyContinue | Out-Null
            fsutil behavior set disable8dot3 1 -ErrorAction SilentlyContinue | Out-Null
            Write-Log "Da tat ghi nhan LastAccessTime va 8dot3Name (giup tang toc HDD)." "SUCCESS"
        }
    } catch {
        Write-Log "Loi khi toi uu o dia: $_" "WARN"
    }
}

function Set-Hibernate {
    param([bool]$Enable = $false)
    try {
        if ($Enable) {
            Write-Log "Dang bat Hibernate..." "INFO"
            powercfg -h on | Out-Null
            Write-Log "Da bat Hibernate." "SUCCESS"
        } else {
            Write-Log "Dang tat Hibernate..." "INFO"
            powercfg -h off | Out-Null
            Write-Log "Da tat Hibernate." "SUCCESS"
        }
    } catch {
        Write-Log "Khong the thay doi thiet lap Hibernate." "WARN"
    }
}

function Clean-CarbonBlackStore {
    Write-Log "=== DON DEP CARBON BLACK STORE ===" "INFO"
    $cbPath = Join-Path $env:SystemRoot "CarbonBlack\Store"
    
    if (-not (Test-Path $cbPath)) {
        Write-Log "Khong tim thay thu muc CarbonBlack Store tai: $cbPath. Co the CarbonBlack chua duoc cai dat." "INFO"
        return
    }
    
    # Try to detect Carbon Black services
    $services = Get-Service -Name "cbdefense", "CarbonBlack", "CbEnterpriseSensorService" -ErrorAction SilentlyContinue
    $stoppedServices = @()
    
    if ($services) {
        foreach ($svc in $services) {
            if ($svc.Status -eq "Running") {
                Write-Log "Phat hien dich vu Carbon Black dang chay: $($svc.Name). Dang thu dung dich vu..." "INFO"
                try {
                    Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                    Write-Log "Da dung dich vu $($svc.Name)." "SUCCESS"
                    $stoppedServices += $svc.Name
                } catch {
                    Write-Log "Khong the dung dich vu $($svc.Name) do co che tu ve cua EDR: $_" "WARN"
                }
            }
        }
    } else {
        Write-Log "Khong thay dich vu Carbon Black nao dang hoat dong. Tien hanh don dep truc tiep." "INFO"
    }
    
    # Now try to delete files in the Store folder
    Write-Log "Dang xoa cac file trong: $cbPath ..." "INFO"
    try {
        $files = Get-ChildItem -Path $cbPath -Recurse -File -ErrorAction SilentlyContinue
        if ($files.Count -eq 0) {
            Write-Log "Thu muc CarbonBlack Store trong, khong co file can xoa." "SUCCESS"
        } else {
            $deletedCount = 0
            $failCount = 0
            foreach ($file in $files) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $deletedCount++
                } catch {
                    $failCount++
                }
            }
            if ($deletedCount -gt 0) {
                Write-Log "Da xoa thanh cong $deletedCount file event/log." "SUCCESS"
            }
            if ($failCount -gt 0) {
                Write-Log "Khong the xoa $failCount file (do file dang bi khoa boi tien trinh khac hoac quyen bao ve cua EDR)." "WARN"
            }
        }
        
        # Try to delete subdirectories if any
        $dirs = Get-ChildItem -Path $cbPath -Recurse -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            try {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
        
    } catch {
        Write-Log "Co loi khi truy cap hoac xoa thu muc CarbonBlack: $_" "ERROR"
    }
    
    # Restart the stopped services
    if ($stoppedServices.Count -gt 0) {
        foreach ($svcName in $stoppedServices) {
            Write-Log "Dang khoi dong lai dich vu: $svcName ..." "INFO"
            try {
                Start-Service -Name $svcName -ErrorAction Stop
                Write-Log "Da khoi dong lai dich vu $svcName." "SUCCESS"
            } catch {
                Write-Log "Khong the khoi dong lai dich vu $($svcName) - $_" "ERROR"
            }
        }
    }
    
    Write-Log "Hoan thanh don dep Carbon Black Store." "SUCCESS"
}

function Invoke-SystemTweaks {
    param(
        [Parameter(Mandatory=$true)]
        [string]$option,
        [bool]$Interactive = $true
    )
    switch ($option) {
        "1" { Clean-SystemTempFiles }
        "2" {
            $confirm = $false
            if ($Interactive) {
                $confirmInput = Read-Host "Ban co muon RESET IP STACK (co the gay mat ket noi mang tam thoi)? (Y/N)"
                if ($confirmInput -eq "Y" -or $confirmInput -eq "y") { $confirm = $true }
            }
            Optimize-Network -ResetIP $confirm
        }
        "3" { Optimize-Performance }
        "4" {
            $confirm = $false
            if ($Interactive) {
                $confirmInput = Read-Host "Ban co muon VO HIEU HOA Windows Search (anh huong den Outlook va Start menu)? (Y/N)"
                if ($confirmInput -eq "Y" -or $confirmInput -eq "y") { $confirm = $true }
            }
            Optimize-Services -DisableSearch $confirm
        }
        "5" { Clean-WindowsUpdateCache }
        "6" { Optimize-Drives }
        "7" { Set-Hibernate -Enable $false }
        "8" { Clean-CarbonBlackStore }
        "9" {
            Write-Log "Thuc hien tat ca cac tuy chon toi uu he thong..." "INFO"
            Clean-SystemTempFiles
            Optimize-Network -ResetIP $false
            Optimize-Performance
            Optimize-Services -DisableSearch $false
            Clean-WindowsUpdateCache
            Optimize-Drives
            Set-Hibernate -Enable $false
            Clean-CarbonBlackStore
            Write-Log "Hoan thanh toan bo cac tweak toi uu he thong." "SUCCESS"
        }
        default { Write-Log "Lua chon khong hop le trong System Tweaks." "WARN" }
    }
}


# Printer Management functions for vdn_ToolKit

function Remove-AllPrinters {
    Write-Log "Dang quet danh sach may in tren he thong..." "INFO"
    try {
        $printers = Get-Printer | Where-Object { 
            $_.Name -notlike "*Microsoft Print to PDF*" -and 
            $_.Name -notlike "*Microsoft XPS Document Writer*" -and 
            $_.Name -notlike "*Fax*" -and
            $_.Name -notlike "*OneNote*"
        }
        if ($null -eq $printers -or $printers.Count -eq 0) {
            Write-Log "Khong tim thay may in nguoi dung nao can xoa." "INFO"
            return
        }
        
        $count = 0
        foreach ($p in $printers) {
            Write-Log "Dang xoa may in: $($p.Name) ..." "INFO"
            try {
                Remove-Printer -Name $p.Name -Confirm:$false -ErrorAction Stop
                Write-Log "Da xoa may in: $($p.Name)" "SUCCESS"
                $count++
            } catch {
                Write-Log "Khong the xoa may in $($p.Name): $_" "ERROR"
            }
        }
        Write-Log "Da xoa thanh cong $count may in." "SUCCESS"
    } catch {
        Write-Log "Loi khi truy cap danh sach may in: $_" "ERROR"
    }
}


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

