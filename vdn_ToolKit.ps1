<#
.SYNOPSIS
    vdn ToolKit - Bo cong cu quan tri he thong Windows
.DESCRIPTION
    Hien thi thong tin, kiem tra ban quyen, kich hoat Windows/Office,
    cai dat phan mem, toi uu he thong, quan ly may in, xuat bao cao HTML.
    Chay voi quyen Administrator.
#>

#region Tu dong nang quyen Admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}
#endregion

#region Tao thu muc tam va tai file cau hinh
$baseDir = Join-Path $env:USERPROFILE "tempkit"
if (-not (Test-Path $baseDir)) { New-Item -ItemType Directory -Path $baseDir -Force | Out-Null }
$toolkitDir = Join-Path $baseDir "vdn_ToolKit_$([System.Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $toolkitDir -Force | Out-Null

$repoUrl = "https://raw.githubusercontent.com/vynguyenit/vnd_ToolKit_ps/main"
$configUrl = "$repoUrl/config/software.json"
$configPath = Join-Path $toolkitDir "software.json"
try {
    Invoke-WebRequest -Uri $configUrl -OutFile $configPath -ErrorAction Stop
} catch {
    Write-Warning "Khong tai duoc cau hinh phan mem. Su dung danh sach mac dinh."
    # Tao file mac dinh neu khong tai duoc
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
    $defaultJson | Out-File -FilePath $configPath -Encoding UTF8
}
#endregion

#region Dinh nghia cac ham chuc nang

function Get-SystemInfo {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = $cs.Name
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $disk = Get-PSDrive -Name C | Select-Object @{N="Size(GB)";E={[math]::Round($_.Used/1GB + $_.Free/1GB,2)}}, @{N="Free(GB)";E={[math]::Round($_.Free/1GB,2)}}
    Write-Host "Ten may: $($cs.Name)"
    Write-Host "Domain: $($cs.Domain)"
    Write-Host "He dieu hanh: $($os.Caption) (Build $($os.BuildNumber))"
    Write-Host "CPU: $cpu"
    Write-Host "RAM: $ram GB"
    Write-Host "O C: $($disk.'Size(GB)') GB (trong $($disk.'Free(GB)') GB)"
}

function Get-WindowsLicenseInfo {
    $output = & slmgr /dli 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Host "Loi khi doc ban quyen Windows."; return }
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
    Write-Host "Edition: $edition"
    Write-Host "Trang thai: $status"
    Write-Host "Loai license: $licenseType"
    Write-Host "Key cuoi: $key"
    Write-Host "`n--- Chi tiet ---"
    Write-Host $output
}

function Get-OfficeLicenseInfo {
    $officePaths = @(
        @{path="C:\Program Files\Microsoft Office\Office14\ospp.vbs"; version="Office 2010"},
        @{path="C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs"; version="Office 2010"},
        @{path="C:\Program Files\Microsoft Office\Office15\ospp.vbs"; version="Office 2013"},
        @{path="C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs"; version="Office 2013"},
        @{path="C:\Program Files\Microsoft Office\Office16\ospp.vbs"; version="Office 2016/2019"},
        @{path="C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs"; version="Office 2016/2019"},
        @{path="C:\Program Files\Microsoft Office\Office19\ospp.vbs"; version="Office 2019"},
        @{path="C:\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"; version="Office 2019"}
    )
    $found = $false
    Write-Host "=== BAN QUYEN OFFICE ==="
    foreach ($item in $officePaths) {
        $path = $item.path
        $version = $item.version
        if (Test-Path $path) {
            $found = $true
            try {
                $output = & cscript $path /dstatus 2>&1 | Out-String
                $lines = $output -split "`r`n"
                $product = ""; $status = ""; $key = ""
                foreach ($line in $lines) {
                    if ($line -match "PRODUCT ID:\s*(.+)") { $product = $matches[1] }
                    if ($line -match "LICENSE STATUS:\s*(.+)") { $status = $matches[1] }
                    if ($line -match "Last 5 characters:\s*(.+)") { $key = $matches[1] }
                }
                Write-Host "`n--- $version ---"
                Write-Host "  Product: $product"
                Write-Host "  Trang thai: $status"
                Write-Host "  Key cuoi: $key"
            } catch {
                Write-Host "Loi khi doc $path : $_"
            }
        }
    }
    if (-not $found) {
        Write-Host "Khong tim thay Office MSI. Kiem tra Office 365..."
        $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        if (Test-Path $regPath) {
            $product = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).ProductReleaseIds
            Write-Host "Office 365/Click-to-Run: $product"
        }
    }
}

function Activate-Windows {
    $key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
    Write-Host "Dat key: $key"
    $out1 = & slmgr /ipk $key 2>&1 | Out-String
    Write-Host $out1
    Write-Host "`nKich hoat voi KMS server..."
    $out2 = & slmgr /ato 2>&1 | Out-String
    Write-Host $out2
    if ($LASTEXITCODE -eq 0) { Write-Host "`nKich hoat thanh cong!" } 
    else { Write-Host "`nKich hoat that bai. Kiem tra ket noi mang." }
}

function Activate-Office {
    $key = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
    $officePaths = @(
        "C:\Program Files\Microsoft Office\Office14\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office15\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office16\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office19\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"
    )
    $found = $false
    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            $found = $true
            Write-Host "Phat hien Office tai $path"
            $out1 = & cscript $path /inpkey:$key 2>&1 | Out-String
            Write-Host $out1
            $out2 = & cscript $path /act 2>&1 | Out-String
            Write-Host $out2
        }
    }
    if (-not $found) {
        Write-Host "Khong tim thay Office. Vui long kiem tra thu cong."
    }
}

function Remove-WindowsLicense {
    $out1 = & slmgr /upk 2>&1 | Out-String
    Write-Host $out1
    $out2 = & slmgr /cpky 2>&1 | Out-String
    Write-Host $out2
    Write-Host "Da xoa ban quyen Windows."
}

function Remove-OfficeLicense {
    $officePaths = @(
        "C:\Program Files\Microsoft Office\Office14\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office15\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office16\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
        "C:\Program Files\Microsoft Office\Office19\ospp.vbs",
        "C:\Program Files (x86)\Microsoft Office\Office19\ospp.vbs"
    )
    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            Write-Host "Dang xoa key tai $path"
            $output = & cscript $path /dstatus 2>&1 | Select-String "Last 5 characters"
            $keys = $output | ForEach-Object { if ($_ -match "Last 5 characters: (.+)") { $matches[1] } }
            foreach ($key in $keys) {
                if ($key) {
                    $out = & cscript $path /unpkey:$key 2>&1 | Out-String
                    Write-Host $out
                }
            }
        }
    }
    Write-Host "Da xoa cac key Office."
}

function Show-SoftwareList {
    $appList = Get-AppList
    $i = 1
    foreach ($app in $appList) {
        Write-Host "[$i] $($app.name)"
        $i++
    }
}

function Get-AppList {
    if (Test-Path $configPath) {
        $json = Get-Content $configPath | ConvertFrom-Json
        return $json.apps
    } else {
        # Mac dinh
        return @(
            @{name="7-Zip"; id="7zip.7zip"; url=""},
            @{name="Google Chrome"; id="Google.Chrome"; url=""},
            @{name="Microsoft Edge"; id="Microsoft.Edge"; url=""},
            @{name="LibreOffice"; id="LibreOffice.LibreOffice"; url=""},
            @{name="OnlyOffice"; id="ONLYOFFICE.ONLYOFFICE"; url=""},
            @{name=".NET Runtime 4.8"; id="Microsoft.DotNet.Runtime.4_8"; url=""},
            @{name=".NET Runtime 6"; id="Microsoft.DotNet.Runtime.6"; url=""},
            @{name=".NET Runtime 8"; id="Microsoft.DotNet.Runtime.8"; url=""},
            @{name="Notepad++"; id="Notepad++.Notepad++"; url=""},
            @{name="Telegram"; id="Telegram.TelegramDesktop"; url=""},
            @{name="Zalo"; id="Zalo.Zalo"; url=""},
            @{name="KillerPDF"; id=""; url="https://download.killerpdf.com/KillerPDFSetup.exe"}
        )
    }
}

function Install-SelectedSoftware {
    param($selections)
    $appList = Get-AppList
    $selectedIndexes = $selections -split " "
    Write-Host "`n=== BAT DAU CAI DAT ==="
    foreach ($idx in $selectedIndexes) {
        $num = [int]$idx
        if ($num -ge 1 -and $num -le $appList.Count) {
            $app = $appList[$num-1]
            $name = $app.name
            $id = $app.id
            $url = $app.url

            if ($id -and $id -ne "") {
                Write-Host "Dang cai $name (winget: $id)..."
                $proc = Start-Process -FilePath "winget" -ArgumentList "install $id --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
                if ($proc.ExitCode -eq 0) {
                    Write-Host "  [+] $name cai thanh cong."
                } else {
                    Write-Host "  [-] $name cai that bai (ma $($proc.ExitCode))."
                }
            } elseif ($url -and $url -ne "") {
                Write-Host "Dang tai $name tu $url ..."
                try {
                    $installer = Join-Path $env:TEMP "$( [System.IO.Path]::GetFileName($url) )"
                    Invoke-WebRequest -Uri $url -OutFile $installer -ErrorAction Stop
                    Write-Host "  Tai thanh cong. Dang cai dat..."
                    $proc = Start-Process -FilePath $installer -ArgumentList "/quiet /norestart" -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0) {
                        Write-Host "  [+] $name cai thanh cong."
                    } else {
                        Write-Host "  [-] $name cai that bai (ma $($proc.ExitCode))."
                    }
                    Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "  [-] Loi tai hoac cai: $_"
                }
            } else {
                Write-Host "  [-] Khong co ID winget va URL cho $name. Bo qua."
            }
        }
    }
}

function Invoke-SystemTweaks {
    param($option)
    switch ($option) {
        "1" { 
            Write-Host "[1] Don rac he thong..."
            $temp = $env:TEMP
            $exclude = (Get-Item $toolkitDir).Name
            Get-ChildItem -Path $temp -Directory -Exclude $exclude | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $temp -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Da don rac."
        }
        "2" {
            Write-Host "[2] Toi uu mang..."
            ipconfig /flushdns | Out-Null
            netsh int ip reset | Out-Null
            netsh winsock reset | Out-Null
            Write-Host "  Da reset Winsock/IP."
        }
        "3" {
            Write-Host "[3] Toi uu hieu suat..."
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f | Out-Null
            Write-Host "  Da thiet lap High Performance, giam tre menu."
        }
        "4" {
            Write-Host "[4] Tat dich vu khong can thiet..."
            $services = @("DiagTrack", "SysMain", "WSearch")
            foreach ($svc in $services) {
                & sc.exe stop $svc 2>$null | Out-Null
                & sc.exe config $svc start= disabled 2>$null | Out-Null
                Write-Host "  Da tat $svc."
            }
        }
        "5" {
            Write-Host "[5] Xoa cache Windows Update..."
            net stop wuauserv | Out-Null
            net stop bits | Out-Null
            Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
            net start wuauserv | Out-Null
            net start bits | Out-Null
            Write-Host "  Da xoa cache."
        }
        "6" {
            Write-Host "[6] Toi uu o dia..."
            $disk = (Get-Partition -DriveLetter C).DiskNumber
            $media = (Get-PhysicalDisk -DeviceNumber $disk).MediaType
            if ($media -eq "SSD") {
                Optimize-Volume -DriveLetter C -ReTrim | Out-Null
                Write-Host "  SSD: da kich hoat TRIM."
            } else {
                fsutil behavior set disablelastaccess 1 | Out-Null
                fsutil behavior set disable8dot3 1 | Out-Null
                Write-Host "  HDD: da toi uu NTFS (khong defrag)."
            }
        }
        "7" {
            Write-Host "[7] Tat Hibernate..."
            powercfg -h off | Out-Null
            Write-Host "  Da tat Hibernate."
        }
        "8" {
            Write-Host "Thuc hien TAT CA cac tuy chon toi uu..."
            Invoke-SystemTweaks -option "1"
            Invoke-SystemTweaks -option "2"
            Invoke-SystemTweaks -option "3"
            Invoke-SystemTweaks -option "4"
            Invoke-SystemTweaks -option "5"
            Invoke-SystemTweaks -option "6"
            Invoke-SystemTweaks -option "7"
            Write-Host "`n=== HOAN THANH TOI UU ==="
        }
        default { Write-Host "Lua chon khong hop le." }
    }
}

function Remove-AllPrinters {
    $printers = Get-Printer | Where-Object { $_.Name -notlike "*Microsoft Print to PDF*" -and $_.Name -notlike "*Microsoft XPS*" -and $_.Name -notlike "*Fax*" }
    if ($printers.Count -eq 0) {
        Write-Host "Khong co may in nao de xoa."
        return
    }
    foreach ($p in $printers) {
        Remove-Printer -Name $p.Name -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Da xoa: $($p.Name)"
    }
    Write-Host "`nXoa thanh cong $(($printers).Count) may in."
}

function Export-HTMLReport {
    $reportPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "vdn_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    # Gom cac thong tin
    $sysInfo = Get-SystemInfo 2>&1 | Out-String
    $winLic = Get-WindowsLicenseInfo 2>&1 | Out-String
    $offLic = Get-OfficeLicenseInfo 2>&1 | Out-String
    $report = @"
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>vdn ToolKit Report</title>
<style>body{font-family:Segoe UI;background:#2d2d30;color:#d0d0d0;padding:20px}h1{color:#4ec9b0}</style>
</head>
<body>
<h1>Bao cao he thong - vdn ToolKit</h1>
<h2>Thong tin may</h2>
<pre>$sysInfo</pre>
<h2>Ban quyen Windows</h2>
<pre>$winLic</pre>
<h2>Ban quyen Office</h2>
<pre>$offLic</pre>
</body></html>
"@
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Bao cao da luu tai: $reportPath"
    Start-Process $reportPath
}

#endregion

#region Menu chinh
do {
    Clear-Host
    Write-Host "=================================================="
    Write-Host "         vdn ToolKit - He thong & Ban quyen"
    Write-Host "=================================================="
    Write-Host ""
    Write-Host "[1] Thong tin he thong"
    Write-Host "[2] Ban quyen Windows"
    Write-Host "[3] Ban quyen Office"
    Write-Host "[4] Kich hoat Windows (KMS)"
    Write-Host "[5] Kich hoat Office (KMS)"
    Write-Host "[6] Xoa ban quyen Windows (Nguy hiem)"
    Write-Host "[7] Xoa ban quyen Office (Nguy hiem)"
    Write-Host ""
    Write-Host "[8] Cai dat phan mem (winget)"
    Write-Host "[9] Toi uu he thong (Optimizer)"
    Write-Host ""
    Write-Host "[A] Quan ly may in"
    Write-Host "[E] Xuat bao cao HTML"
    Write-Host "[H] Huong dan su dung"
    Write-Host "[0] Thoat"
    Write-Host ""
    Write-Host "=================================================="
    $choice = Read-Host "Chon chuc nang [1,2,3...A,E,H,0]"

    switch ($choice) {
        "1" { Clear-Host; Write-Host "=== THONG TIN HE THONG ==="; Get-SystemInfo; Read-Host "Nhan Enter de tiep tuc" }
        "2" { Clear-Host; Write-Host "=== BAN QUYEN WINDOWS ==="; Get-WindowsLicenseInfo; Read-Host "Nhan Enter de tiep tuc" }
        "3" { Clear-Host; Write-Host "=== BAN QUYEN OFFICE ==="; Get-OfficeLicenseInfo; Read-Host "Nhan Enter de tiep tuc" }
        "4" { 
            Clear-Host; Write-Host "=== KICH HOAT WINDOWS (KMS) ==="
            $confirm = Read-Host "Ban co muon tiep tuc? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { Activate-Windows }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "5" {
            Clear-Host; Write-Host "=== KICH HOAT OFFICE (KMS) ==="
            $confirm = Read-Host "Ban co muon tiep tuc? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { Activate-Office }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "6" {
            Clear-Host; Write-Host "=== XOA BAN QUYEN WINDOWS (NGUY HIEM) ==="
            Write-Host "CANH BAO: Hanh dong nay se xoa ban quyen Windows."
            $confirm = Read-Host "Ban co chac chan? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { Remove-WindowsLicense }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "7" {
            Clear-Host; Write-Host "=== XOA BAN QUYEN OFFICE (NGUY HIEM) ==="
            Write-Host "CANH BAO: Hanh dong nay se xoa ban quyen Office."
            $confirm = Read-Host "Ban co chac chan? (Y/N)"
            if ($confirm -eq "Y" -or $confirm -eq "y") { Remove-OfficeLicense }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "8" {
            Clear-Host; Write-Host "=== CAI DAT PHAN MEM (WINGET) ==="
            Show-SoftwareList
            $selections = Read-Host "Nhap so thu tu phan mem can cai (cach nhau dau cach, vi du: 1 3 5)"
            Install-SelectedSoftware -selections $selections
            Read-Host "Nhan Enter de tiep tuc"
        }
        "9" {
            Clear-Host; Write-Host "=== TOI UU HE THONG (OPTIMIZER) ==="
            Write-Host ""
            Write-Host "[1] Don rac he thong (Temp, Prefetch, Recent)"
            Write-Host "[2] Toi uu mang (Flush DNS, Reset Winsock)"
            Write-Host "[3] Toi uu hieu suat (High Performance, Menu delay)"
            Write-Host "[4] Tat dich vu khong can thiet (SysMain, DiagTrack, WSearch)"
            Write-Host "[5] Xoa cache Windows Update"
            Write-Host "[6] Toi uu o dia (SSD TRIM / HDD NTFS)"
            Write-Host "[7] Tat Hibernate"
            Write-Host "[8] THUC HIEN TAT CA"
            Write-Host "[0] Quay lai"
            $tweakChoice = Read-Host "Chon [1-8 hoac 0]"
            if ($tweakChoice -ne "0") { Invoke-SystemTweaks -option $tweakChoice }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "A" {
            Clear-Host; Write-Host "=== QUAN LY MAY IN ==="
            Write-Host "[1] Xoa sach may in (giu driver)"
            Write-Host "[2] Mo Print Management (cai dat may in)"
            Write-Host "[0] Quay lai"
            $printerChoice = Read-Host "Chon [1,2 hoac 0]"
            if ($printerChoice -eq "1") {
                $confirm = Read-Host "Ban co chac muon xoa tat ca may in? (Y/N)"
                if ($confirm -eq "Y" -or $confirm -eq "y") { Remove-AllPrinters }
            } elseif ($printerChoice -eq "2") {
                Start-Process "printmanagement.msc"
            }
            Read-Host "Nhan Enter de tiep tuc"
        }
        "E" {
            Clear-Host; Write-Host "=== XUAT BAO CAO HTML ==="
            Export-HTMLReport
            Read-Host "Nhan Enter de tiep tuc"
        }
        "H" {
            Clear-Host
            Write-Host "=== HUONG DAN SU DUNG ==="
            Write-Host ""
            Write-Host "vdn ToolKit - Bo cong cu quan tri he thong"
            Write-Host ""
            Write-Host "CAC CHUC NANG CHINH:"
            Write-Host " 1. Thong tin he thong - Hien thi CPU, RAM, o dia, OS"
            Write-Host " 2. Ban quyen Windows - Kiem tra trang thai kich hoat"
            Write-Host " 3. Ban quyen Office - Kiem tra trang thai kich hoat"
            Write-Host " 4. Kich hoat Windows - Su dung key KMS (W269N-...)"
            Write-Host " 5. Kich hoat Office - Su dung key KMS (FXYTK-...)"
            Write-Host " 6. Xoa ban quyen Windows - Xoa key khoi he thong"
            Write-Host " 7. Xoa ban quyen Office - Xoa key khoi he thong"
            Write-Host " 8. Cai dat phan mem - Cai qua winget hoac tai truc tiep"
            Write-Host " 9. Toi uu he thong - Don rac, toi uu mang, hieu suat, SSD/HDD"
            Write-Host " A. Quan ly may in - Xoa may in hoac mo Print Management"
            Write-Host " E. Xuat bao cao HTML - Luu vao thu muc Documents"
            Write-Host " H. Hien thi huong dan nay"
            Write-Host " 0. Thoat"
            Write-Host ""
            Write-Host "LUU Y:"
            Write-Host " - Can chay voi quyen Administrator"
            Write-Host " - Ket noi Internet can thiet cho mot so chuc nang"
            Write-Host " - Cac thao tac danh dau 'Nguy hiem' can xac nhan truoc khi thuc hien"
            Read-Host "Nhan Enter de tiep tuc"
        }
        "0" { 
            Write-Host "Dang don dep..."
            Remove-Item -Path $toolkitDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Tam biet!"
            break
        }
        default { Write-Host "Lua chon khong hop le."; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "0")

#endregion