# Tai lieu Ky thuat & Phat trien vdn ToolKit

Tai lieu nay danh cho lap trinh vien hoac nguoi quan tri muon phat trien, mo rong hoac tuy bien **vdn ToolKit**.

---

## 1. Kien truc Modular

He thong phan chia chuc nang thanh cac file script rieng biet trong thu muc `src/`:

1. **`00_Params.ps1`**: Khai bao tham so dau vao. Bat buoc phai nam dau file phan phoi de PowerShell hieu duoc cac tham so `param(...)`.
2. **`Core.ps1`**:
   - `Write-Log`: Ham in log ra man hinh kem mau sac theo cap do (`INFO`, `SUCCESS`, `WARN`, `ERROR`).
   - `Confirm-AdminPrivilege`: Kiem tra quyen Administrator, tu dong khoi chay lai voi quyen cao neu chua co.
   - `Get-AppList` va `Download-Configuration`: Tai file cau hinh phan mem tu URL github hoac dung cau hinh mac dinh du phong.
3. **`Licensing.ps1`**:
   - `Get-WindowsLicenseInfo` / `Get-OfficeLicenseInfo`: Doc thong tin ban quyen bang slmgr va ospp.vbs.
   - `Activate-Windows` / `Activate-Office`: Kich hoat qua KMS.
   - `Remove-WindowsLicense` / `Remove-OfficeLicense`: Go sach ban quyen tren may.
4. **`Software.ps1`**:
   - Cai dat phan mem thong qua winget hoac tu tai link truc tiep va chay silent install (/quiet /norestart).
5. **`Optimizer.ps1`**:
   - Chua cac tweak toi uu o dia (SSD TRIM/HDD cache), he thong (Temp files), dich vu, Windows Update, va dac biet la don dep CarbonBlack Store.
6. **`Printer.ps1`**:
   - Quan ly may in, xoa may in nguoi dung, khoi chay printmanagement.msc.
7. **`Main.ps1`**:
   - Xu ly dieu huong (routing) khi chay CLI va chay giao dien Menu chinh.

---

## 2. Huong dan Build (Compile)

Khi ban sua doi bat ky code nao trong thu muc `src/`, hay chay script `build.ps1` o thu muc goc:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

**Hoat dong cua build.ps1:**
- Ghep noi cac script tu `src/` theo thu tu kien truc vao file `vdn_ToolKit.ps1`.
- Dung PowerShell Parser `[System.Management.Automation.Language.Parser]` de quet loi cu phap cua file output.
- Neu phat hien bat ky loi cu phap nao (ngoai le, dau ngoac, sai ten bien...), qua trinh build se dung lai va thong bao loi chi tiet.

---

## 3. Huong dan Them/Bot Phan mem

Ban co the tuy chinh phan mem trong file `config/software.json`. Cau truc:

```json
{
  "apps": [
    {
      "name": "Ten hien thi",
      "id": "winget.package.id",
      "url": "https://url-tai-ve.com/setup.exe"
    }
  ]
}
```

- **id**: dung de cai qua Winget (khuyen khich vi nhanh va an toan). De trong neu khong ho tro.
- **url**: duong dan truc tiep tai file setup (toolkit se tu tai va chay silent voi `/quiet /norestart`). De trong neu chi dung winget.

---

## 4. Giai thich ve Don dep CarbonBlack Store

- **Duong dan**: `%SystemRoot%\CarbonBlack\Store` (thuong la `C:\Windows\CarbonBlack\Store`).
- **Co che hoat dong**:
  1. Quet xem thu muc ton tai khong.
  2. Tim cac dich vu lien quan (`cbdefense`, `CarbonBlack`, `CbEnterpriseSensorService`) va co gang tat chung.
  3. Quet va xoa toan bo cac file log/event trong thu muc `Store`.
  4. Su dung `try/catch` de bo qua cac file bi khoa hoac bi EDR bao ve (tamper protection) ma khong gay loi dung script.
  5. Khoi dong lai cac dich vu CarbonBlack da tat.