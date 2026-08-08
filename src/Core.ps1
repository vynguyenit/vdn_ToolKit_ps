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
