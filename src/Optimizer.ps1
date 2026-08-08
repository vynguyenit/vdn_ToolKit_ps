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
