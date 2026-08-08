# vdn ToolKit

**vdn ToolKit** la bo cong cu quan tri he thong Windows chuyen nghiep va an toan, duoc viet bang PowerShell. Cong cu giup don dep, toi uu hoa, kiem tra thong tin phan cung, quan ly ban quyen Windows va Office, cai dat phan mem hang loat thong qua giao dien dong lenh (CLI) va menu tuong tac.

---

## Tinh nang chinh

- **Thong tin he thong**: Hien thi thong tin chi tiet ve ten may, domain, phien ban OS, CPU, RAM va trang thai dung luong o dia C.
- **Ban quyen Windows & Office**: Kiem tra trang thai kich hoat, loai license (KMS, OEM, Retail...) va khoa san pham cuoi.
- **Kich hoat KMS**: Ho tro kich hoat nhanh Windows va Office bang cac khoa KMS mac dinh.
- **Go bo ban quyen**: Go sach key Windows va Office khoi he thong (yeu cau xac nhan an toan).
- **Cai dat phan mem**: Ho tro winget hoac tai truc tiep va cai silent tu file cau hinh `software.json`.
- **Toi uu he thong**:
  - Don dep rac he thong (Temp, Prefetch, Recent).
  - Toi uu mang (Flush DNS, Reset Winsock, Reset TCP/IP voi canh bao).
  - Toi uu hieu suat (Power Plan High Performance, giam tre Menu).
  - Quan ly dich vu (Tat Telemetry, Superfetch an toan).
  - Xoa cache Windows Update.
  - Toi uu o dia (SSD TRIM / HDD NTFS).
  - Tat Hibernate.
  - **Don dep CarbonBlack Store**: Giai phong dung luong thu muc event/log cua CarbonBlack EDR tai `%SystemRoot%\CarbonBlack\Store` (co kiem tra khoa va quyen EDR).
- **Quan ly may in**: Xoa sach cac may in nguoi dung hoac mo Print Management Console.
- **Ho tro CLI**: Hoat dong khong can menu tuong tac, phu hop cho tu dong hoa qua RMM hoac script he thong.

---

## Cau truc thu muc du an (Modular)

Bo toolkit duoc thiet ke modular khoa hoc de de dang phat trien va bao tri:

```text
vnd_ToolKit_ps/
├── config/
│   └── software.json      # File cau hinh phan mem cai dat
├── docs/
│   └── README.md          # Huong dan nha phat trien chi tiet
├── src/                   # Cac file module chuc nang
│   ├── 00_Params.ps1      # Khai bao tham so script (CLI)
│   ├── Core.ps1           # Logger, kiem tra Admin, quan ly cau hinh
│   ├── Licensing.ps1      # Kiem tra & kich hoat Windows/Office
│   ├── Software.ps1       # Cai dat phan mem (winget/silent URL)
│   ├── Optimizer.ps1      # Don dep, tweaks, va CarbonBlack Store
│   ├── Printer.ps1        # Quan ly may in
│   └── Main.ps1           # Router tham so va loop Menu chinh
├── build.ps1              # Script ghep cac module src/ thanh vdn_ToolKit.ps1
├── vdn_ToolKit.ps1        # Script phan phoi cuoi cung (generated)
└── README.md              # Huong dan su dung chung
```

---

## Cach build (Danh cho nha phat trien)

Khi thay doi code trong thu muc `src/`, hay chay script build de cap nhat file phan phoi:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

Script se tu dong ghep cac module va kiem tra loi cu phap truoc khi luu.

---

## Cach chay

### 1. Giao dien Menu tuong tac
Mo **PowerShell (Admin)** va chay:
```powershell
powershell -ExecutionPolicy Bypass -File vdn_ToolKit.ps1
```

### 2. Che do Dong lenh (CLI - Khong can GUI/Menu)
Ho tro truyen tham so de tu dong hoa:
```powershell
powershell -ExecutionPolicy Bypass -File vdn_ToolKit.ps1 -Action <TenAction> [-Apps '<Indices>'] [-TweakOption <Option>] [-Silent]
```

Cac tham so:
- `-Action`: Hanh dong thuc hien (`SysInfo`, `WinLicense`, `OfficeLicense`, `ActivateWin`, `ActivateOffice`, `RemoveWinLic`, `RemoveOfficeLic`, `InstallApps`, `Optimize`, `CleanCarbonBlack`, `CleanPrinters`).
- `-Apps`: So thu tu phan mem can cai dat (cach nhau bang khoang trang), e.g. `'1 3'`.
- `-TweakOption`: Sub-option khi dung `-Action Optimize` (tu `1` den `9`).
- `-Silent`: Chay o che do im lang khong hoi xac nhan.

**Vi du:**
- Toi uu he thong silent (thuc hien tat ca tweak an toan):
  ```powershell
  powershell -ExecutionPolicy Bypass -File vdn_ToolKit.ps1 -Action Optimize -TweakOption 9 -Silent
  ```
- Don dep CarbonBlack Store:
  ```powershell
  powershell -ExecutionPolicy Bypass -File vdn_ToolKit.ps1 -Action CleanCarbonBlack
  ```
- Cai dat Google Chrome (index 2) va Edge (index 3) tu dong:
  ```powershell
  powershell -ExecutionPolicy Bypass -File vdn_ToolKit.ps1 -Action InstallApps -Apps '2 3'
  ```
