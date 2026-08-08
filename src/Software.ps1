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
