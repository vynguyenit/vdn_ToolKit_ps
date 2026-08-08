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
